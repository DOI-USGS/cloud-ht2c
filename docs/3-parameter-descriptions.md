# Parameter Descriptions

The HTCondor Service Catalog Product supports a variety of parameters, which enable customization and optimization of the cluster.

## Parameters

### Network Configuration

#### Name Prefix

Enter a `string` that will be prefixed on the deployed resources (EC2 Instance and Volume, the EFS FileSystem). Enter something unique to easily identify which resources are related to your HTCondor Cluster.

#### VPC

The VPC to launch the HT Condor Cluster (control and worker nodes) in. You must create this prior to deploying the CloudFormation stack.

#### Subnets

The Subnets to launch the HT Condor Cluster into. All subnets must belong to the selected VPC. A minimum of three subnets are required for the 3 EFS mounts to be created.

#### CIDR Range

The CIDR range to grant inbound access to the Control Node. Because the Control Nodes run behind a Network Load Balancer, ingress for the HT Condor ports (9618, 9700-9710) must be granted by CIDR Range, a self-referencing security group cannot be used. It is recommended to use the combined CIDR range of the selected subnets, in order to minimize unnecessary access.

### Controller Configuration

#### Control Node Instance Type

The instance type to launch the control node on. Does not require compute power for jobs, it just acts as the coordinator for tasks. For jobs using high amounts of data, a high performance memory and/or networking instance is recommended.

#### Control Node Volume Size

The root EBS Volume size to attach to the controller node. The controller node uses EFS for condor storage, so this volume size does not need be large enough to contain all computational data.

#### Control Node AMI ID

The AMI to launch the Control Node with. CentOS 7 is required for network settings. The CloudFormation template will install cfn-bootstrap, awscliv2, and HTCondor (latest) at boot on top of this AMI. The following region-dependent AMIs are good for getting started:

- `ami-08c191625cfb7ee61` will work in the `us-west-2` region **only** (default)
- `ami-0dee0f906cf114191` will work in the `us-west-1` region **only**
- `ami-05a36e1502605b4aa` will work in the `us-east-2` region **only**
- `ami-002070d43b0a4f171` will work in the `us-east-1` region **only**

### Worker Configuration

#### Number of Worker Nodes to launch

Set the number of worker nodes to spin up. Can be updated at any time in order to adjust available compute resources or save on costs.

#### Worker Node Instance Type

The instance type to launch the worker nodes on. Needs vary depending on the workflow. High-performance compute, memory, and network instances are available.

#### Worker Node Volume Size

The root EBS Volume size to attach to the worker nodes.

#### Worker Node AMI ID

The AMI to launch the worker node with. CentOS 7 is required for network settings. The CloudFormation template will install cfn-bootstrap, awscliv2, and HTCondor (latest) at boot on top of this AMI. The following region-dependent AMIs are good for getting started:

- `ami-08c191625cfb7ee61` will work in the `us-west-2` region **only** (default)
- `ami-0dee0f906cf114191` will work in the `us-west-1` region **only**
- `ami-05a36e1502605b4aa` will work in the `us-east-2` region **only**
- `ami-002070d43b0a4f171` will work in the `us-east-1` region **only**

### Advanced Configuration

#### Existing EFS ID

The Elastic File System (EFS) ID (efs-asdfasdf) of an existing FileSystem. Leave this parameter blank in order to create a new FileSystem. If an existing FileSystem is specified, the product will deploy a MountTarget in the first three subnets previously specified in the Subnets parameter.

#### Control Node Instance Profile

The name of an existing Instance Profile to be attached to the Control Node. Leave blank to create a new role with the required permissions. Requires SSM, ReadOnly, and Autoscaling actions.

#### Worker Node Instance Profile

The name of an existing Instance Profile to be attached to the Worker Nodes. Leave blank to create a new role with the required permissions. Requires SSM, ReadOnly, and Autoscaling actions.
