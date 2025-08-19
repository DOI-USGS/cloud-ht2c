# Parameter Descriptions

The HTCondor Service Catalog Product supports a variety of parameters, which
enable customization and optimization of the cluster.

## Parameters

### Network Configuration

#### Name Prefix

Enter a `string` that will be prefixed on the deployed resources (EC2 Instance
and Volume, the EFS FileSystem). Enter something unique to easily identify which
resources are related to your HTCondor Cluster.

#### VPC

The VPC to launch the HT Condor Cluster (control and worker nodes) in. You must
create this prior to deploying the CloudFormation stack.

#### Subnets

The Subnets to launch the HT Condor Cluster into. All subnets must belong to the
selected VPC. A minimum of three subnets are required for the 3 EFS mounts to be
created.

#### CIDR Range

The CIDR range to grant inbound access to the Control Node. Because the Control
Nodes run behind a Network Load Balancer, ingress for the HT Condor ports (9618,
9700-9710) must be granted by CIDR Range, a self-referencing security group
cannot be used. It is recommended to use the combined CIDR range of the selected
subnets, in order to minimize unnecessary access. (hint, you may be able to use one of the addresses selected in Subnets, eg xxx.xxx.xxx.xxx/xx)

### Controller Configuration

#### Control Node Instance Type

The instance type to launch the control node on. Does not require compute power
for jobs, it just acts as the coordinator for tasks. For jobs using high amounts
of data, a high performance memory and/or networking instance is recommended.

#### Control Node Volume Size

The root EBS Volume size to attach to the controller node. The controller node
uses EFS for condor storage, so this volume size does not need be large enough
to contain all computational data.

#### Control Node AMI ID

The AMI to launch the worker node with. This will depend on the OS and stack you
are using.

### Worker Configuration

#### Number of Worker Nodes to launch

Set the number of worker nodes to spin up. Can be updated at any time in order
to adjust available compute resources or save on costs.

#### Worker Node Instance Type

The instance type to launch the worker nodes on. Needs vary depending on the
workflow. High-performance compute, memory, and network instances are available.

#### Worker Node Volume Size

The root EBS Volume size to attach to the worker nodes.

#### Worker Node AMI ID

The AMI to launch the worker node with. This will depend on the OS and stack you
are using.

#### Worker Node Timeout `pWorkerNodeTimeout`

The number of seconds a Worker node may remain unclaimed by HTCondor before
automatically terminating itself and removing the desired capacity of the
AutoScaling Group by one. This is a cost-saving parameter intended to terminate
unneeded nodes as larger HTCondor jobs come to a close. Set to `0` to disable.

Default: `600` seconds

#### Worker Node KillSwitch TimeStamp `pWorkerNodeKillSwitchTimeStamp`

A timestamp designated at launch time when the AutoScaling group will
__terminate all worker nodes__ and scale the ASG down to zero. The Control Node
will be unaffected by this process. This is a cost-saving parameter intended to
provide a timestamp to forcibly scale-in all workers at a designated time. Set
to `NULL` to disable.

Default: `NULL`

#### Worker Node Instance Profile `pWorkerNodeInstanceProfile`

__Optional:__ The friendly name (`Logical ID`) of the IAM Role to use for the
Worker Node. If not specified, a default IAM Role will be created for you.

### Advanced Configuration

#### Existing EFS ID

The Elastic File System (EFS) ID (efs-asdfasdf) of an existing FileSystem. Leave
this parameter blank in order to create a new FileSystem. If an existing
FileSystem is specified, the product will deploy a MountTarget in the first
three subnets previously specified in the Subnets parameter.

#### Control Node Instance Profile

The name of an existing Instance Profile to be attached to the Control Node.
Leave blank to create a new role with the required permissions. Requires SSM,
ReadOnly, and Autoscaling actions.

#### Worker Node Instance Profile

The name of an existing Instance Profile to be attached to the Worker Nodes.
Leave blank to create a new role with the required permissions. Requires SSM,
ReadOnly, and Autoscaling actions.
