#!/bin/bash

set -euo pipefail
DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "--> Cleanup VMs"
sudo virsh list --all | (grep -E "(admin|(master|worker)_[0-9]+)" || :) | awk '{print $2}' | \
  xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh destroy {}; sudo virsh undefine {}'

echo "--> Cleanup Networks"
sudo virsh net-list --all | (grep "caasp-dev-net" || :) | awk '{print $1}' | \
  xargs --no-run-if-empty -n1 -I{} sh -c 'sudo virsh net-destroy {}; sudo virsh net-undefine {}'

echo "--> Cleanup Volumes"
pools="$(sudo virsh pool-list --all | sed 1,2d | awk '{print $1}')"
for pool in $pools; do
sudo virsh vol-list --pool "$pool" | \
  (grep -E -e "admin(_cloud_init)?" \
           -e "(master|worker)(_cloud_init)?_[0-9]+" \
           -e "additional-worker-volume" \
           -e "SUSE-CaaS-Platform-.*KVM.*Build[0-9]+\.[0-9]+" \
  || :) | \
  awk '{print $1}' \
  | xargs --no-run-if-empty -n1 -I{} sudo virsh vol-delete --pool "$pool" '{}'
done

echo "--> Cleanup Terraform states from caasp-kvm"
pushd $DIR/.. > /dev/null
rm -f cluster.tf terraform.tfstate*
popd  > /dev/null

echo "--> Cleanup old KVM images"
pushd $DIR/../../downloads > /dev/null
ls -vr *.qcow2 | awk -F- '$1 == name{system ("rm -f \""$0"\"")}{name=$1}' 
popd  > /dev/null

echo "--> Cleanup screenshots"
pushd $DIR/../../velum-bootstrap > /dev/null
rm -rf screenshots 
popd  > /dev/null

echo "Creanup Done"
