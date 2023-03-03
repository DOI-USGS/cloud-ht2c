# HTCondor Amazon Machine Images (AMIs)

HTCondor nodes can be launched with pre-staged software in the form of [Amazon Machine Images (AMIs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html). This is useful if you don't want to wait for a large software library to be downloaded and installed each time you spin up a fresh cluster. It is recommended to generate AMIs for your HTCondor nodes with the software you need, such as HTCondor, Docker, and Python3, etc. General information on creating an AMI with an EC2 instance can be found in [Create your own AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html#creating-an-ami), but the general steps are as follows:

## 1. Launch and Prepare an EC2 Instance

1. **NOTE:** Currently, **CentOS 7** is required for network settings. The AMI must have [awscli](https://aws.amazon.com/cli/), the [CloudWatch Logs agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html), and [cfn-signal](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html) installed to correctly provision
1. Launch the EC2 instance you will use to create your AMI: [Launch your instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html)
1. Configure your EC2 instance to allow connections: [Connect to your Linx instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstances.html)
1. Connect to your instance (e.g., using System Manager (SSM) or with SSH)
1. Install all necessary software (see **1.** above)
1. You may create separate AMIs for the HTCondor Control Node and Worker Nodes, if desired

## 2. Create an AMI

Once you've installed and configured the desired software on your EC2 instance, you can create a new AMI from it. Future EC2 instances can be launched from that AMI, and will have that software already configured. To create the new AMI:

1. Navigate to the EC2 Service
2. Select `Instances` and select the EC2 instance you previously configured
3. Select `Actions` -> `Image and templates` -> `Create image`
4. Enter the image name, description, and any tags. Select `Create Image`
5. Select `AMIs`. Locate the image you just created based on its name and description
6. Note the AMI ID (e.g., `ami-asdf1234`) of your new AMI
7. Wait for the AMI to reach the `Available` status

## 4. Use the AMI in HTCondor

You can now use your custom AMI within your HTCondor cluster. To launch a new cluster with the AMI, follow the standard launch process, inputting your AMI ID (`ami-asdf1234`) in the `Worker Node AMI ID` and/or `Control Node AMI ID` parameters.

To update an existing cluster, follow the standard update process, inputting your AMI ID (`ami-asdf1234`) in the `Worker Node AMI ID` and/or `Control Node AMI ID` parameters.
