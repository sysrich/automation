# CaaSP OpenStack Heat

This directory contains the caasp-openstack-heat tool. This tool builds a CaaSP cluster
on OpenStack with minimal effort. This tool is not suitable for development clusters, as
no code is injected into the cluster.

It's primary purpose is for building large scale CaaSP clusters on OpenStack for testing
and validation.

## Requirements

You can install the necessary dependancy packages with:

    $ sudo zypper in jq python-openstackclient python-novaclient python-heatclient

## CLI Syntax

    > ./caasp-openstack --help
    Usage:

      * Building a cluster

        -b|--build                       Run the Heat Stack Build Step
        -w|--workers             <INT>   Number of workers to build
        -i|--image               <STR>   Image to use

      * Destroying a cluster

        -d|--destroy                     Run the Heat Stack Destroy Step

      * Common options

        -o|--openrc             <STR>   Path to an openrc file
        -e|--heat-environment   <STR>   Path to a heat environment file

      * Examples:

      Build a 2 worker cluster

      ./caasp-openstack --build -w 2 --openrc my-openrc --image CaaSP-1.0.0-GM --name test-stack

## Using a cluster

The nodes booted will all be listed in the generated environment.json file, please refer to this
file for IP addresses etc.
