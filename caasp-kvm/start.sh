#!/bin/bash

terraform apply
./tools/generate_environment.sh
echo "Waiting for Velum to start - this may take a while"
./tools/wait_for_velum.py https://$(jq -r '.dashboardHost' environment.json)
echo "CaaS Platform Ready for bootstrap"
