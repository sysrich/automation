#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "--> Cleanup VMs"
sudo virsh list --all | (grep -E "caasp_(admin|(master|worker)_[0-9]+)" || :) | awk '{print $2}' | xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh destroy {}; sudo virsh undefine {}'

echo "--> Cleanup Networks"
sudo virsh net-list --all | (grep "caasp-net" || :) | awk '{print $1}' | xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh net-destroy {}; sudo virsh net-undefine {}'

echo "--> Cleanup Volumes"
sudo virsh vol-list --pool default | (grep -E "caasp_(admin(_cloud_init)?|(master|worker)(_cloud_init)?_[0-9]+)" || :) | awk '{print $1}' | xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh vol-delete --pool default {}'

echo "--> Cleanup Terraform states from caasp-kvm"
pushd $DIR/.. > /dev/null
rm -f cluster.tf terraform.tfstate*
popd  > /dev/null

echo "Creanup Done"
