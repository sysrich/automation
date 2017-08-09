#!/bin/sh
set -eux

FILE=$1
SSH_CONFIG=$2
POSARGS=${3:-}

for role in "worker" "master" "admin"; do
    ips=$(jq -r "[.minions[] | select(.role==\"$role\") | .ipv4 ] | join(\",\" )" $FILE)
    if [ -n "$ips" ]
        then
            pytest --ssh-config=$SSH_CONFIG --sudo -m "$role or common" --hosts $ips --junit-xml $role.xml -v $POSARGS
    fi
done

