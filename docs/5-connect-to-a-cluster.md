# Connect to a HTCondor Cluster

Once provisioned, you can connect to the cluster's Control Node to submit and manage jobs.  The Control Node is an EC2 Instance, which you can connect to using using a method of your choice, such as Systems Manager (SSM) or SSH. See [Setting up Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started.html) and [Connect to your Linux instance using SSH](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) for more.


Once connected to your Control node you can now interact with your cluster through the Condor CLI. Run `condor_status` to see the current available worker nodes.

Now that you've connected to the HTCondor Control node, you can begin submitting jobs and performing computations with the cluster. Please visit the [Official HTCondor Documentation](https://htcondor.readthedocs.io/en/latest/users-manual/welcome-to-htcondor.html) for more info on running jobs. You can follow the [HTCondor Quick Start Guide](https://htcondor.readthedocs.io/en/latest/users-manual/quick-start-guide.html) to run your first job.

