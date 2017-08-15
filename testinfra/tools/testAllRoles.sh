#!/bin/sh
set -eux

FILE=$1
SSH_CONFIG=$2
POSARGS=${3:-}
ENVIRONMENT_JSON=$FILE
for role in "worker" "master" "admin"; do
    fqdns=$(jq -r "[.minions[] | select(.role==\"$role\") | .fqdn ] | join(\",\" )" $FILE)
    if [ -n "$fqdns" ]; then
        pytest --ssh-config=$SSH_CONFIG --connection ssh --sudo -m "$role or common" --hosts $fqdns --junit-xml $role.xml -v $POSARGS
    fi
done
