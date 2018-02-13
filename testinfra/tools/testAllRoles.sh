#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

ENVIRONMENT_JSON=$1
SSH_CONFIG=$2
POSARGS=${3:-}

ADMIN_MINION=$(cat $ENVIRONMENT_JSON  | jq -r '.minions[] | select(.role=="admin") | .fqdn')

ssh -F $SSH_CONFIG caasp-admin.devenv.caasp.suse.net -- "docker exec -i \$(docker ps | grep salt-master | awk '{print \$1}') salt --output json '*' grains.get fqdn" > $DIR/fqdn.json
ssh -F $SSH_CONFIG caasp-admin.devenv.caasp.suse.net -- "docker exec -i \$(docker ps | grep salt-master | awk '{print \$1}') salt --output json '*' grains.get roles" > $DIR/roles.json

cat $DIR/fqdn.json | jq -s '[.[] | to_entries[] | {"key": .key, "value": {"fqdn": .value}}] | from_entries' > $DIR/fqdn-mapped.json
cat $DIR/roles.json | jq -s '[.[] | to_entries[] | {"key": .key, "value": {"roles": .value}}] | from_entries' > $DIR/roles-mapped.json

for role in "admin" "etcd" "kube-master" "kube-minion"; do
	fqdns=$(cat $DIR/mapped.json | jq -r "[.[] | select(.roles[] | contains(\"$role\")) | .fqdn ] | join(\"\n\")")
    if [ -n "$fqdns" ]; then
        echo pytest --ssh-config=$SSH_CONFIG --connection ssh --sudo -m "$role or common" --hosts $fqdns --junit-xml $role.xml -v $POSARGS
    fi
done
