#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

source  "$DIR/../misc-tools/functions"

USAGE=$(cat <<USAGE
Usage:

  $0         destroy the cluster

USAGE
)

# parse options
while [[ $# > 0 ]] ; do
  case $1 in
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  shift
done

#######################################################################

export CAASP_PROVIDER="openstack-terraform"

terraform destroy

