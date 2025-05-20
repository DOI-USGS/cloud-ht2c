#!/bin/bash

# Shell script to initialize EC2 mirroring Ansible playbook in this repo
# chs-amazon-linux-2-stig-20230308143612: ami-049998ccc3d3f86b5
# CONTROLLER NODE

usage () { echo "How to use -r REGION -n STACK_NAME -s STACK_ID [ -e EFS_ID ] "; }

options=':hr:n:s:e:'
while getopts $options option
do
    case "$option" in
        r  ) REGION=$OPTARG;;
        n  ) STACK_NAME=$OPTARG;;
        s  ) STACK_ID=$OPTARG;;
        e  ) EFS_ID=$OPTARG;;
        # t  ) WORKER_TIMEOUT=$OPTARG;;
        h  ) usage; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$option" >&2; exit 1;;
    esac
done

# mandatory arguments
if [[ -z "$REGION" ]] \
  || [[ -z "$STACK_NAME" ]] \
  || [[ -z "$STACK_ID" ]]
then
  echo "arguments -r, -n, and -s must be provided"
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
  instance_id="$( curl -H "X-aws-ec2-metadata-token: ${TOKEN}" -v http://169.254.169.254/latest/meta-data/instance-id )"

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
# Configure HTCondor CONTROLLER NODE
# Outputs:
#   /etc/condor/config.d/config
#######################################
function configure_condor_controller() {
  local target_file="/etc/condor/config.d/config"
  echo "Creating HTCondor Config File for CONTROLLER NODE..."
  echo "Writing ${target_file}"
  # Quotes around "END" required to prevent any variable expansion inside the
  # written file:
  cat << "END" > "${target_file}"
CONDOR_HOST = replaceme
ALLOW_READ = *
ALLOW_WRITE = *
ALLOW_ADMINISTRATOR = $(CONDOR_HOST),  $(IP_ADDRESS)
DAEMON_LIST = MASTER, COLLECTOR, SCHEDD, NEGOTIATOR
FILESYSTEM_DOMAIN = htcondor.chs.usgs.gov
UID_DOMAIN = htcondor.chs.usgs.gov
SUBMIT_ATTRS = RunAsOwner
use role:get_htcondor_central_manager
use role:get_htcondor_submit
END
# See https://htcondor.readthedocs.io/en/latest/man-pages/classads.html
# for more on condor configuration ClassAd expressions

  chown root:root "${target_file}"
  chmod 644 "${target_file}"

  local my_ip
  my_ip=$( curl -H "X-aws-ec2-metadata-token: ${TOKEN}" -v http://169.254.169.254/latest/meta-data/local-ipv4 )
  echo "Obtained self IP address: ${my_ip}"
  /bin/sed -i "s/replaceme/${my_ip}/g" "${target_file}"
  echo -n "HTCondor10#" | sh -c "condor_store_cred add -c -i -"
  sh -c "umask 0077; condor_token_create -identity condor@${my_ip} > /etc/condor/tokens.d/condor@${my_ip}"
  iptables -I INPUT -i eth0 -p tcp --dport 9618 -j ACCEPT && service iptables save
  iptables -I INPUT -i eth0 -p tcp --dport 9700:9710 -j ACCEPT && service iptables save
  rm -f /etc/condor/config.d/00-htcondor-9.0.config /etc/condor/config.d/00-minicondor
  systemctl restart condor
}

function main() {
  tag_volumes
  set_max_open_files
  mount_efs
  configure_condor_controller
}

main "$@"
