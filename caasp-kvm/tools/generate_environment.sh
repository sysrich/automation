#!/bin/bash
set -eux
chmod 600 tools/id_docker
if command -v jq; then
    echo "Generating environment.json file"
    environment=$(cat terraform.tfstate | \
        jq ".modules[].resources[] | select(.type==\"libvirt_domain\") | .primary | .attributes | { fqdn: .metadata | split(\",\") | .[0], ipv4: .[\"network_interface.0.addresses.0\"], role: .metadata | split(\",\") | .[1], index: .metadata | split(\",\") | .[2] } " | jq -s . | jq "{minions: .}")
    echo "$environment" | jq .
    
    for node in $(echo "$environment" | jq -r '.minions[] | select(.["minion_id"]? == null) | [.ipv4] | join(" ")'); do
        machine_id=$(ssh root@$node -i tools/id_docker  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no cat /etc/machine-id)
        environment=$(echo "$environment" | jq ".minions | map(if (.ipv4 == \"$node\") then . + {\"minionID\": \"$machine_id\"} else . end) | {minions: .}")
    done
    environment=$(echo "$environment" | jq " . + {dashboardHost: .minions[] | select(.role==\"admin\") | .ipv4, kubernetesHost: .minions[] | select(.role==\"master\") | .ipv4}")
    environment=$(echo "$environment" | jq " . + {sshKey: \"`pwd`/tools/id_docker\", sshUser: \"root\"}")
    echo "$environment" | tee environment.json
else
    echo "jq is not installed - please install jq to generate the environment.json file"
fi
