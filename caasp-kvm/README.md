This directory contains a list of file that allow a fast and automated deployment
of a CaaSP cluster.

This is different from the [kubic devenv](https://github.com/kubic-project/caasp-devenv)
because it's only focus is to allow the creation of a cluster based on our
official KVM image.

The purpose of this cluster is not the development of new features, rather the
testing of it or the reproduction of bugs. Hence this is pretty useful for
people working inside of the
[bug squad](https://gitlab.suse.de/docker/DOCS/wikis/bug-squad), QA Engineers and
even Sales Engineers doing demonstrations.

These files will take care of:

  * Create an admin node and a customizable number of generic nodes,
    all of them based on the KVM image of CaaSP chosen by the user.
  * The nodes are tweaked by cloud-init, exactly as our customers would do.
  * The salt minion processes on the generic nodes are already configured to
    point back to the salt master running on the admin node.
  * The actual deployment of the cluster has to be done using the velum interface
    running on the admin node. Exactly as our customers would do.

# Requirements

The [Terraform](https://github.com/hashicorp/terraform) and the
[terraform-provider-libvirt](https://github.com/dmacvicar/terraform-provider-libvirt)
providers must be installed.

We maintain packages for both of them inside of the
[Virtualization:containers](https://build.opensuse.org/project/show/Virtualization:containers)
project on OBS.

You can add this repo and install these packages with just

```
$ # (replace openSUSE_Leap_42.2 with your distro)
$ sudo zypper ar obs://Virtualization:containers/openSUSE_Leap_42.2 Virtualization:containers
$ sudo zypper in terraform-provider-libvirt jq
```

You are going to need a working libvirt daemon capable of using KVM.

# Cluster configuration

The deployment can be tuned using some terraform variables. All of them
are defined at the top of the `cluster.tf` file. Each variable has also a
description field that explains its purpose.

These are the most important ones:

  * `libvirt_uri`: by default this points to localhost, however it's possible
    to perform the deployment on a different libvirt machine. More on that later.
  * `caasp_img_source_url`: this is the URL of the CaaSP image to be used to
    create the whole cluster.
  * `caasp_cluster_nodes_count`: number of non-admin nodes to be created.

The easiest way to set these values is by creating a `terraform.tfvars`. The
project comes with an example file named `terraform.tfvars.example`.

## Getting the CaaSP image

The CaaSP image to be used must be specified by the user. The image is
downloaded on the machine running the terraform script inside of the directory
where this project has been checked out. Then the image is uploaded to the
libvirtd pool.

This extra step is done to ensure the image being used is never ever lost. IBS
keeps rebuilding the image and older ones are automatically removed. The image
is also removed from the libvirt pool by the `terraform destroy` command.
This makes harder to test regressions between different builds.

The image downloaded inside of the git checkout is *never ever* removed by
terraform. It must be deleted manually by the user once it's no longer
needed.

The download is performed by a simple python script invoked automatically by
terraform during the `apply` stage. The script won't download the image if it's
already available inside of the git checkout. This ensures no time has to
be wasted, plus everything will work fine even when the image is no longer
available inside of IBS.

## cloud-init

The project comes with two cloud-init files: one for the admin node, the other
for the generic nodes.

Feel free to edit them to suit your needs. Right now they are based on the files
used by our QA engineers.

Note well: the system is going to have a `root` and a `qa` users, both with 
password `linux` and the ssh key in `tools/id_docker`

# Cluster architecture

The cluster is made of 1 admin node and the number of generic nodes chosen by
the user.

All the nodes are based on the same CaaSP image and will have the same amount of
memory.

All of them have a cloud-init ISO attached to them to inject the cloud-init
configuration.

All the nodes are attached to the `default` network of libvirt. This is a network
that satisfies CaaSP's basic network requirement: there's a DHCP and a DNS
enabled but the DNS server is not able to resolve the names of the nodes inside
of that network.

# Creating the cluster

Steps to perform:

  * Configure the cluster the way you want (see above section).
  * Execute: `terraform apply`

At the end of the deployment you will see the IP address of the admin server, 
and the IP addresses of the master and worker VMs. There will also be an
`environement.json` file describing the VMs and their roles. Use the velum instance 
running inside of the admin node to deploy the CaaSP cluster.

# Using a remote libvirt machine

Most of us are using their laptops as primary working machines but they cannot
deploy a CaaSP cluster on them because there's not enough memory.

This terraform project allows to create the cluster on a remote libvirt host,
one that is more powerful than our laptops.

To do that:

  * Install libvirt on a remote machine.
  * Ensure the user who runs the terraform script can ssh into the remote machine
    as `root` without using a password (log into it using ssh-key, load the ssh-key
    via `ssh-agent` or use a passwordless one).
  * Create a `terraform.tfvars` file with the following line: `libvirt_uri = "qemu+ssh://root@arrakis/system"`
    where `arrakis` is the name of your remote host.

Once the deployment is done you won't be able to access the velum instance
running on the admin node. That's happening because the nodes are inside of
the `default` libvirt network that is reachable only by the host running libvirtd.

To operate the cluster you have two possibilities:

  1. The lazy one: `ssh -X` into the remote host, start a browser and point it
    to the admin node.
  2. The smart one: `ssh -L 22222:192.168.100.143:80 flavio@arrakis` this will
    tunnel velum running on the admin node (IP `192.168.100.143`) on your laptop
    on port `22222`.

Once the deployment is done you have to figure out the IP address of the kubernetes
API server. This right now is tricky from the velum UI.

To get the IP address of the admin node you have to:

  * ssh into the admin node
  * Execute the following command: `docker exec -it $(docker ps | grep salt-master | awk '{print $1}') salt -G 'roles:*master*' grains.get ipv4`
