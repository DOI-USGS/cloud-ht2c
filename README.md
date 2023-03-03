# Cloud HT2C

[AWS Cloudformation](https://aws.amazon.com/cloudformation/) configuration for
high-throughput computing with [HTCondor](http://htcondor.org), supported by
USGS [HyTEST](https://www.usgs.gov/mission-areas/water-resources/science/integrated-water-prediction-iwp)
project and [Cloud Hosting Solutions](https://www.usgs.gov/associate-chief-information-officer/cloud-hosting-solutions)

## Table of Contents

[[_TOC_]]

## Requirements

- AWS Account
- AWS VPC with at least three subnets
- AWS AMIs for HTCondor Control and Worker Nodes
- Data to process

## Overview

The [htcondor.yml](./cloudformation/htcondor.yml) template file in this
repository creates a CloudFormation stack with all necessary AWS resources for
a Linux-based HTCondor cluster on-demand. This version is an Alpha release
(v. 0.1) with new capabilities and further documentation to come.

## Documentation

1. [Create Base Image](./docs/1-create-base-image.md)
1. [Launch a New Cluster](./docs/2-launch-a-new-cluster.md)
1. [Parameter Descriptions](./docs/3-parameter-descriptions.md)
1. [Update a Cluster](./docs/4-update-a-cluster.md)
1. [Connect to a Cluster](./docs/5-connect-to-a-cluster.md)

## Additional Information

- [Disclaimer](./DISCLAIMER.md)
- [License](./LICENSE.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)
- [Contributing](./CONTRIBUTING.md)

## Information for PEST users
A common application for this software will be distributed model analysis using [PEST](http://pesthomepage.org) and [PEST++](https://github.com/usgs/pestpp/). For information on integrating PEST/PEST++ with HTCondor, see [Fienen and Hunt, 2015](https://ngwa.onlinelibrary.wiley.com/doi/10.1111/gwat.12320).

The port range of 9700-9710 is available for PEST/PEST++ communications between the Control Node and Worker Nodes.

## Contact Information

You may communicate with the authors in this repo or reach out to Mike Fienen at
mnfienen@usgs.gov
