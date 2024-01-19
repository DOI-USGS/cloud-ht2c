# HTCondor Amazon Machine Images (AMIs)

HTCondor nodes can be launched with pre-staged software in the form of [Amazon
Machine Images
(AMIs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html). This is
useful if you don't want to wait for a large software library to be downloaded
and installed each time you spin up a fresh cluster. The CloudFormation stack
accepts AMI IDs in the `ControlNodeAmiId` and `WorkerNodeAmiId` parameters, and
it installs the minimum necessary dependencies needed by the HTCondor cluster on
every instance:

- [cfn-bootstrap](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html#cfn-helper-scripts-reference-downloads)
- [awscliv2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [ssm-agent](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html)
- [HTCondor](https://htcondor.readthedocs.io/en/latest/getting-htcondor/admin-quick-start.html)
  (latest version using **get_htcondor**)

The HTCondor cluster stacks can only deploy on Amazon Linux 2 or CentOS 7 AMIs
at this time. The official AMIs for use in the following US regions are:

- Amazon Linux 2
  - `ami-0df24e148fdb9f1d8` will work in the `us-west-2` region **only**
    (default)
  - `ami-0925fd223898ee5ba` will work in the `us-west-1` region **only**
  - `ami-02238ac43d6385ab3` will work in the `us-east-2` region **only**
  - `ami-005f9685cb30f234b` will work in the `us-east-1` region **only**
- CentOS 7
  - `ami-08c191625cfb7ee61` will work in the `us-west-2` region **only**
    (default)
  - `ami-0dee0f906cf114191` will work in the `us-west-1` region **only**
  - `ami-05a36e1502605b4aa` will work in the `us-east-2` region **only**
  - `ami-002070d43b0a4f171` will work in the `us-east-1` region **only**

The HTCondor cluster functional with Amazon Linux 2023 is the most recent
version of the stack and is compatible with HTCondor v23. You must create this
AMI before launching the CloudFormation Stack:

1. Launch an EC2 in your desired region running Amazon Linux 2023
1. Install `ansible` with `yum install -y ansible`
1. Connect to your instance, and run the Ansible Playbook included in this repo
   at
   [htcondor-al2023/ansible/playbook.yml](../htcondor-al2023/ansible/playbook.yml)
   with:

```bash
ansible-pull -U https://github.com/DOI-USGS/cloud-ht2c.git -i localhost htcondor-al2023/ansible/playbook.yml
# Or, to check the ansible configuration using a particular git repo branch:
ansible-pull -U https://github.com/DOI-USGS/cloud-ht2c.git -i localhost htcondor-al2023/ansible/playbook.yml --check --checkout 2-bring-into-parity-with-chs-stack
```

1. Create an AMI from the EC2 instance's current state (see below)

You may [Find a Linux
AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/finding-an-ami.html) on
AWS, or you may create one yourself if you'd like to include other dependencies
(e.g., Docker) prior to launching the cluster (but note that `cfn-bootstrap`,
`awscliv2`, and `HTCondor` are installed on all instances at boot time). General
information on creating an AMI with an EC2 instance can be found in [Create your
own
AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html#creating-an-ami),
but the general steps are as follows:

## 1. Launch and Prepare an EC2 Instance

1. **NOTE:** Currently, **CentOS 7** is required for network settings. The AMI
   must have [awscli](https://aws.amazon.com/cli/), the [CloudWatch Logs
   agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html),
   and
   [cfn-signal](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html)
   installed to correctly provision
1. Launch the EC2 instance you will use to create your AMI: [Launch your
   instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html)
1. Configure your EC2 instance to allow connections: [Connect to your Linux
   instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstances.html)
1. Connect to your instance (e.g., using System Manager (SSM) or with SSH)
1. Install all necessary software (see **1.** above)
1. You may create separate AMIs for the HTCondor Control Node and Worker Nodes,
   if desired

## 2. Create an AMI

Once you've installed and configured the desired software on your EC2 instance,
you can create a new AMI from it. Future EC2 instances can be launched from that
AMI, and will have that software already configured. To create the new AMI:

1. Navigate to the EC2 Service
2. Select `Instances` and select the EC2 instance you previously configured
3. Select `Actions` -> `Image and templates` -> `Create image`
4. Enter the image name, description, and any tags. Select `Create Image`
5. Select `AMIs`. Locate the image you just created based on its name and
   description
6. Note the AMI ID (e.g., `ami-asdf1234`) of your new AMI
7. Wait for the AMI to reach the `Available` status

## 4. Use the AMI in HTCondor

You can now use your custom AMI within your HTCondor cluster. To launch a new
cluster with the AMI, follow the standard launch process, inputting your AMI ID
(`ami-asdf1234`) in the `Worker Node AMI ID` and/or `Control Node AMI ID`
parameters.

To update an existing cluster, follow the standard update process, inputting
your AMI ID (`ami-asdf1234`) in the `Worker Node AMI ID` and/or `Control Node
AMI ID` parameters.
