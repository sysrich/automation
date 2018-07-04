#!/bin/bash
set -e
SECRET=$(ssh -i ssh/id_ses sles@$1 sudo ceph auth get-key client.admin | base64)
jq -n --arg secret "$SECRET" '{"secret":$secret}'

