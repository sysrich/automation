# CaaSP KVM

This directory contains the caasp-kvm tool, aimed at replacing the existing caasp-devenv
and terraform repositories.

A primary goal of caasp-kvm is to reduce the number of places where our development
enviroments differ from a customer environemnt, allowing us to more easily ensure our
changes really will work in the final product.

## Requirements

The [Terraform](https://github.com/hashicorp/terraform) and the
[terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt)
providers must be installed.

We maintain packages for both of them inside of the
[Virtualization:containers](https://build.opensuse.org/project/show/Virtualization:containers)
project on OBS.

You can add this repo and install these packages with just

    $ # (replace openSUSE_Leap_42.2 with your distro)
    $ sudo zypper ar obs://Virtualization:containers/openSUSE_Leap_42.2 Virtualization:containers
    $ sudo zypper in terraform terraform-provider-libvirt jq

## CLI Syntax

    > ./caasp-kvm --help
    Usage:

      * Building a cluster

        -b|--build                       Run the CaaSP KVM Build Step
        -m|--masters             <INT>   Number of masters to build
        -w|--workers             <INT>   Number of workers to build
        -i|--image               <STR>   Image to use

      * Destroying a cluster

        -d|--destroy                     Run the CaaSP KVM Destroy Step

      * Common options

        -p|--parallelism                 Set terraform parallelism

      * Examples:

      Build a 1 master, 2 worker cluster

      ./caasp-kvm --build -m 1 -w 2

      Build a 1 master, 2 worker cluster using the latest staging A image

      ./caasp-kvm --build -m 1 -w 2 --image channel://staging_a

      Destroy a cluster

      ./caasp-kvm --destroy

## Using a cluster

The nodes booted will be given fixed/deterministic IP addresses, it it recommended
you create a ~/.ssh/config with the following content, adjusting the SSH key path
as necessary:

    Host 10.17.*
        User root
        IdentityFile /home/kiall/SUSE/caasp/automation/misc-files/id_shared
        UserKnownHostsFile /dev/null
        StrictHostKeyChecking no

Each node will have an determinisic IP address, and additional nodes will have the
final octet incremented by 1:

* Admin node will have 10.17.1.0
* First master node will have 10.17.2.0
* First worker node will have 10.17.3.0
