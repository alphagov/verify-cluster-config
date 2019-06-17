# Verify GSP Cluster Configuration

[GSP](https://github.com/alphagov/gsp) Cluster configuration for Verify.

## Overview

This repository is the entrypoint for:

* Configuring the namespaces present in the cluster
* Configuring variables used by the main gsp cluster deployment pipeline
* Configuring the scale of the cluster (ie max number of nodes, instance sizes etc)

See [GSP](https://github.com/alphagov/gsp) for more information

## Deploying changes

Changes to this repository:

* Are continuously deployed by concourse on merge to master.
* Require commits signed by [Trusted Developers](https://github.com/alphagov/gds-trusted-developers/).
* Require approvals by authorized users.




