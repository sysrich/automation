#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"
ENVIRONMENT=${ENVIRONMENT:-$DIR/../caasp-kvm/environment.json}
SSH_KEY=$(cat $ENVIRONMENT | jq -r '.sshKey')
REPO=${1:-http://download.suse.de/ibs/Devel:/CASP:/Head:/ControllerNode/standard}
ALIAS=${2:-Extra}
MINIONS=""

while read minion_json; do
  FQDN=$(echo -n "$minion_json" | jq -r '.fqdn')
  [[ $FQDN =~ admin ]] && continue
  IPV4=$(echo -n "$minion_json" | jq -r 'if (.addresses.publicIpv4 == null) then .addresses.privateIpv4 else .addresses.publicIpv4 end')
  MINIONS="$MINIONS $IPV4"
done <<< "$(cat $ENVIRONMENT | jq -c '.minions[]')"

for minion in $MINIONS; do
  echo ">>> adding $ALIAS repo with url: $REPO to $minion"
  ssh -q -i $SSH_KEY root@$minion zypper ar --no-gpgcheck $REPO $ALIAS
done
