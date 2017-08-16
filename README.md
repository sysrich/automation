# Kubic Project Automation

The repo houses various tools and automation scripts that are used by the
Kubic team for dev/test/CI purposes.

## caasp-devenv

A wrapper script which orchestrates several of the other tools to build,
bootstrap, test etc in a single command. For usage, see it's `--help`
output.

## CaaSP KVM

A tool to build a KVM based development cluster.

## CaaSP OpenStack Heat

A tool to build a OpenStack based CaaSP cluster. Well suited to building
large scale clusters for testing and validation.

## CaaSP OpenStack Terraform

A tool to build a OpenStack based CaaSP cluster. Well suited to building
large scale clusters for testing and validation.

## Jenkins Pipelines

A set of Jenkins pipelines which are not directly associated with a specific
repo. e.g. Nightly builds.

## Kubernetes e2e-tests

Some scripting to run the Kubernetes e2e tests against as a CaaSP cluster

## Testinfra Infrastructure Tests

A set of tests to validate a CaaSP cluster has been successfully deployed

## Velum Bootstrap automation

Some scripting to walk through the Velum UI to bootstrap a cluster, primarily
used within CI.
