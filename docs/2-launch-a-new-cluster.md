# Launch a new HTCondor Cluster

You can launch the HTCondor Cluster resources in your AWS account by creating an AWS CloudFormation stack from either the [htcondor-centos-7.yml](../cloudformation/htcondor-centos-7.yml) or [htcondor-amazon-linux-2.yml](../cloudformation/htcondor-amazon-linux-2.yml) file, depending on your desired base OS.

## 1. Launch the CloudFormation Stack

1. In your AWS account, navigate to the CloudFormation console
1. Select `Create stack` > `With new resources (standard)`
1. Select `Template is ready` (selected by default)
1. Select Template source: `Upload a template file`
1. Select `Choose file` and select the file path to the CloudFormation template with the desired OS on your local machine
1. Enter a name for the CloudFormation stack
1. Enter values for the Parameters (see the [Parameter Descriptions](./3-parameter-descriptions.md) for more)
1. Enter values for all other desired settings, and select `Submit`
1. Once the CloudFormation stack has reached the `CREATE_COMPLETE` status, you can connect to your cluster

## 2. Connect to the Cluster

Instructions for connecting to your HTCondor Cluster can be found in the [Connect to a Cluster](./5-connect-to-a-cluster.md) document.
