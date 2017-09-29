# CaaSP KVM

This directory contains the caasp-kvm tool, aimed at replacing the existing caasp-devenv
and terraform repositories.

A primary goal of caasp-kvm is to reduce the number of places where our development
enviroments differ from a customer enviroment, allowing us to more easily ensure our
changes really will work in the final product.

## Requirements

In order to run `caasp-kvm`, a system must have `kvm` installed, `libvirtd` and
`docker` daemons running, and a few additional dependencies must be met. As
root, run:

    zypper in git python-requests qemu-kvm docker virsh libvirt-daemon-qemu
    systemctl enable libvirtd
    systemctl start libvirtd
    systemctl enable docker
    systemctl start docker

Many of the required resources are hosted inside SUSE's private R&D network; in
order to access and connect to these resouces, you may need a SUSE R&D openvpn
connection; see the
[Micro Focus internal wiki](https://wiki.microfocus.net/index.php?title=SUSE-Development/OPS/Services/OpenVPN)
for details.

You must also have SUSE's CA certificates installed, as documented on
http://ca.suse.de . As root:

    # (replace openSUSE_Leap_42.3 with your distro)
    zypper ar --refresh http://download.suse.de/ibs/SUSE:/CA/openSUSE_Leap_42.3/SUSE:CA.repo
    zypper in ca-certificates-suse p11-kit-nss-trust

The user running `caasp-kvm` must be a member of a few additional groups:

    # replace <username> with your username
    usermod -aG docker,libvirtd <username>


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

Clone these repositories:

    $ git clone git@github.com:kubic-project/salt.git
    $ git clone git@github.com:kubic-project/velum.git
    $ git clone git@github.com:kubic-project/caasp-container-manifests.git
    $ git clone git@github.com:kubic-project/automation.git

## CLI Syntax

    $ cd automation/caasp-kvm
    $ ./caasp-kvm --help
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
        -P|--proxy                       Set HTTP Proxy (Default: CAASP_HTTP_PROXY)

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
