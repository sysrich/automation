# kubic-kvm

The goal is to provide a simple setup of three Kubic VMs.

You can extend the main.tf example provided in the `kubic-kvm` dir.

## Prerequisites

You're going to need at least:
* `terraform`
* [`terraform-provider-libvirt`](https://github.com/dmacvicar/terraform-provider-libvirt)

Running `caasp-devenv` should install the packages, otherwise loook on upstream projects. 

# Usage

Run 
    $ terraform init
    $ terraform plan
    $ terraform apply
    
to start the VMs and follow [https://kubic.opensuse.org/blog/2018-08-20-kubeadm-intro/](https://kubic.opensuse.org/blog/2018-08-20-kubeadm-intro/) to initialize Kubernetes.
    
