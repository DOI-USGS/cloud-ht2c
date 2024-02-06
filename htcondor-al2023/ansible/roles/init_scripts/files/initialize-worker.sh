#!/bin/bash

# Shell script to initialize EC2 mirroring Ansible playbook in this repo
# chs-amazon-linux-2-stig-20230308143612: ami-049998ccc3d3f86b5
# WORKER NODE

usage () { echo "How to use arguments: -i CONTROL_NODE_IP -r REGION -n STACK_NAME -s STACK_ID -t WORKER_TIMEOUT [ -e EFS_ID ] "; }

options=':hi:r:n:s:t:e:'
while getopts $options option
do
    case "$option" in
        i  ) CONTROL_NODE_IP=$OPTARG;;
        r  ) REGION=$OPTARG;;
        n  ) STACK_NAME=$OPTARG;;
        s  ) STACK_ID=$OPTARG;;
        e  ) EFS_ID=$OPTARG;;
        t  ) WORKER_TIMEOUT=$OPTARG;;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$option" >&2; exit 1;;
    esac
done

# mandatory arguments
if [[ -z "${CONTROL_NODE_IP}" ]] \
  || [[ -z "${REGION}" ]] \
  || [[ -z "${STACK_NAME}" ]] \
  || [[ -z "${STACK_ID}" ]] \
  || [[ -z  "${WORKER_TIMEOUT}" ]]
then
  echo "arguments -i, -r, -n, -s, and -t must be provided"
  usage >&2; exit 1
fi

# get AWS metadata token for IMDSv2: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html
TOKEN=$( curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" )

#######################################
# Add All EC2 Tags to EC2 Volume(s).
#######################################
function tag_volumes() {
  echo "Tagging EBS volume with all EC2 tags..."
  local instance_id
  instance_id=$( curl -H "X-aws-ec2-metadata-token: ${TOKEN}" -v http://169.254.169.254/latest/meta-data/instance-id )

  local vols
  vols="$(
    /bin/aws ec2 describe-volumes \
      --filters Name=attachment.instance-id,Values="${instance_id}" \
        Name=attachment.device,Values=/dev/xvda --query Volumes[].VolumeId \
      --output text )"

  local ec2_tags
  ec2_tags="$(
    /bin/aws ec2 describe-tags \
      --filters "Name=resource-id,Values=${instance_id}" \
      --query 'Tags[?!starts_with(Key, `aws`) == `true`].{Value:Value,Key:Key}'
  )"

  echo "Tagging volumes:"
  for vol in "${vols[@]}"; do
    echo "${vol}"
    /bin/aws ec2 create-tags --resources "${vol}" --tags "${ec2_tags}"
  done
}

#######################################
# Write ansible Config File: /etc/ansible/ansible.cfg
#######################################
# Ansible should be installed on the AMI, so ideally we could enable logging when the AMI is built
# function enable_ansible_logging() {
#   echo "Enabling Ansible logging in /etc/ansible/ansible.cfg..."
#   sed '/log_path/s/^#//' -i /etc/ansible/ansible.cfg
# }

#######################################
# Override Max Open Files Limit: /etc/sysctl.d/98-open-files.conf
#######################################
function set_max_open_files() {
  echo "Setting max number of concurrent files to 100,000..."
  local target_file="/etc/sysctl.d/98-open-files.conf"
  cat << END > "${target_file}"
fs.file-max = 100000

END
  chown root:root "${target_file}"
  chmod 644 "${target_file}"

  sysctl -p
  echo "* hard nofile 100000" >> /etc/security/limits.conf
  echo "* soft nofile 100000" >> /etc/security/limits.conf
}

#######################################
# Mount EFS to /mnt/condor_working
# Globals:
#   EFS_ID
#   REGION
#######################################
function mount_efs() {
  # If EFS_ID is not defined, continue without running mount_efs
  if [[ -z "${EFS_ID}" ]]; then
      echo "No value provided for EFS_ID, continuing without mounting EFS..."
      return
  fi

  if [[ -n "${EFS_ID}" ]]; then
    echo "Mounting EFS: ${EFS_ID} to /mnt/condor_working..."

    local efs_source_address
    efs_source_address="${EFS_ID}.efs.${REGION}.amazonaws.com:/"

    mkdir -p /mnt/condor_working
    mount -t nfs4 \
      -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
      "${efs_source_address}" \
      /mnt/condor_working
    chmod go+rw /mnt/condor_working

    # Ensure EFS mount on reboot - might only be needed for control node only
    echo "Enabling EFS mount on reboot..."
    echo "${efs_source_address} /mnt/condor_working nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" \
      >> /etc/fstab
  fi
}

#######################################
# Configure ECR credentials for Docker
#######################################
function configure_ecr_credentials() {
  ACCOUNT_ID=$( curl -H "X-aws-ec2-metadata-token: ${TOKEN}" -v http://169.254.169.254/latest/meta-data/identity-credentials/ec2/info | jq '.AccountId' -r )
  local target_file
  target_file="/etc/docker/config.json"

  cat << END > "${target_file}"
{"credHelpers": {"${ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com": "ecr-login"}}
END

  chown root:root "${target_file}"
  chmod 644 "${target_file}"

  cat << END >> "/etc/environment"
DOCKER_CONFIG=/etc/docker
END

  systemctl restart docker

}

#######################################
# Configure HTCondor WORKER NODE
# Globals:
#   CONTROL_NODE_IP
# Outputs:
#   /etc/condor/config.d/config
#######################################
function configure_condor_worker() {
  local target_file
  target_file="/etc/condor/config.d/config"

  echo "Creating HTCondor Config File for WORKER NODE..."
  echo "Writing ${target_file}"
  # Quotes around "END" required to prevent variable expansion in file:
  cat << "END" > "${target_file}"
CONDOR_HOST = condor_host_replaceme
COLLECTOR_HOST = $(CONDOR_HOST)
ALLOW_READ = *
ALLOW_WRITE = *
ALLOW_ADMINISTRATOR = $(CONDOR_HOST),  $(IP_ADDRESS)
SLOT_TYPE_1 = cpu=100%
NUM_SLOTS_TYPE_1 = 1
SLOT_TYPE_1_PARTITIONABLE = True
DAEMON_LIST = MASTER, STARTD, SCHEDD
STARTD_NOCLAIM_SHUTDOWN = shutdown_timeout_replaceme
MASTER.DAEMON_SHUTDOWN = ( STARTD_StartTime == 0 ) && ((CurrentTime - DaemonStartTime) > 60)
MASTER.DAEMON_SHUTDOWN_FAST = ( STARTD_StartTime == 0 ) && ((CurrentTime - DaemonStartTime) > 60)
DEFAULT_MASTER_SHUTDOWN_SCRIPT = /etc/condor/shutdown-worker.sh
FILESYSTEM_DOMAIN = htcondor.efs
DOCKER_VOLUMES = CONDOR_EFS
DOCKER_VOLUME_DIR_CONDOR_EFS = /mnt/condor_working
DOCKER_MOUNT_VOLUMES = CONDOR_EFS
use role:get_htcondor_execute
END
# See https://htcondor.readthedocs.io/en/latest/man-pages/classads.html
# for more on condor configuration ClassAd expressions

  chown root:root "${target_file}"
  chown 444 "${target_file}"

  echo "Applying Control Node IP Address: ${CONTROL_NODE_IP}"
  /bin/sed -i "s/condor_host_replaceme/${CONTROL_NODE_IP}/g" "${target_file}"

  # Test if WORKER_TIMEOUT == 0 to disable auto scale-in of idle worker nodes:
  if [[ "${WORKER_TIMEOUT}" == 0 ]]; then
    echo "Found WORKER_TIMEOUT value: ${WORKER_TIMEOUT}"
    echo "Setting Condor config STARTD_NOCLAIM_SHUTDOWN to UNDEFINED..."
    /bin/sed -i "s/shutdown_timeout_replaceme/False/g" \
      "${target_file}"
  else
    echo "Found WORKER_TIMEOUT value: ${WORKER_TIMEOUT}"
    echo "Setting Condor config STARTD_NOCLAIM_SHUTDOWN to ${WORKER_TIMEOUT}..."
    /bin/sed -i "s/shutdown_timeout_replaceme/${WORKER_TIMEOUT}/g" \
      "${target_file}"
  fi

  echo -n "HTCondor10#" | sh -c "condor_store_cred add -c -i -"
  sh -c "umask 0077; condor_token_create -identity condor@${CONTROL_NODE_IP} > /etc/condor/tokens.d/condor@${CONTROL_NODE_IP}"
  iptables -I INPUT -i eth0 -p tcp --dport 9618 -j ACCEPT && service iptables save
  iptables -I INPUT -i eth0 -p tcp --dport 9700:9710 -j ACCEPT && service iptables save
  rm -f /etc/condor/config.d/00-htcondor-9.0.config /etc/condor/config.d/00-minicondor
  systemctl restart condor
}

function main() {
  tag_volumes
  set_max_open_files
  mount_efs
  configure_ecr_credentials
  configure_condor_worker
}

main "$@"
