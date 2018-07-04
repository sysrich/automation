#!/bin/bash
set -e
key=$(ls ssh/ | grep -v "pub")
SECRET=$(ssh -i ssh/$key  -o BatchMode=yes -o StrictHostKeyChecking=no sles@$1 cat /etc/registry/domain.crt)
jq -n --arg secret "$SECRET" '{"secret":$secret}'
