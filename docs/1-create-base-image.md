# HTCondor Amazon Machine Images (AMIs)

__OPTIONAL:__ HTCondor nodes can be launched with pre-staged software in the
form of [Amazon Machine Images (AMIs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html).

The default Control and Worker Nodes are configured using an
[Ansible](https://docs.ansible.com/ansible/latest/getting_started/index.html)
playbook: [htcondor-al2023/ansible](../htcondor-al2023/ansible/).

## Creating Custom AMIs

### 1. Launch and Prepare an EC2 Instance

1. Launch the EC2 instance you will use to create your AMI: [Launch your
   instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html)
1. Configure your EC2 instance to allow connections: [Connect to your Linux
   instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstances.html)
1. Connect to your instance (e.g., using System Manager (SSM) or with SSH)
1. Install all necessary software
1. You may create separate AMIs for the HTCondor Control Node and Worker Nodes,
   if desired

### 2. Create an AMI

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

### 4. Use the AMI in HTCondor

You can now use your custom AMI within your HTCondor cluster. To launch a new
cluster with the AMI, follow the standard launch process, inputting your AMI ID
(`ami-asdf1234`) in the `Worker Node AMI ID` and/or `Control Node AMI ID`
parameters.

To update an existing cluster, follow the standard update process, inputting
your AMI ID (`ami-asdf1234`) in the `Worker Node AMI ID` and/or `Control Node
AMI ID` parameters.
