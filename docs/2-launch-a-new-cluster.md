# Launch a new HTCondor Cluster

You can launch the HTCondor Cluster resources in your AWS account by creating an AWS CloudFormation stack from the [htcondor.yml](../cloudformation/htcondor.yml) file.

## 1. Launch the CloudFormation Stack

1. In your AWS account, navigate to the CloudFormation console
1. Select `Create stack` > `With new resources (standard)`
1. Select `Template is ready` (selected by default)
1. Select Template source: `Upload a template file`
1. Select `Choose file` and select the file path to the [htcondor.yml](../cloudformation/htcondor.yml) file on your local machine, wherever you have cloned this repository
1. Enter a name for the CloudFormation stack
1. Enter values for the Parameters (see the [Parameter Descriptions](./3-parameter-descriptions.md) for more)
1. Enter values for all other desired settings, and select `Submit`
1. Once the CloudFormation stack has reached the `CREATE_COMPLETE` status, you can connect to your cluster

## 2. Connect to the Cluster

Instructions for connecting to your HTCondor Cluster can be found in the [Connect to a Cluster](./5-connect-to-a-cluster.md) document.
