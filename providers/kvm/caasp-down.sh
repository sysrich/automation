#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

source  "$DIR/../../misc-tools/functions"

PARALLELISM=${CAASP_PARALLELISM:-1}

# the environment file
ENVIRONMENT=${ENVIRONMENT:-$DIR/../environment.json}

################################################################

USAGE=$(cat <<USAGE
Usage: $0    Destroy the cluster

  * Options

    -p|--parallelism       Set terraform parallelism (Default: CAASP_PARALLELISM)

USAGE
)

# parse options
while [[ $# > 0 ]] ; do
  case $1 in
    -p|--parallelism)
      PARALLELISM="$2"
      shift
      ;;
    -h|--help)
      usage
      ;;
  esac
  shift
done

################################################################

export CAASP_PROVIDER="kvm"

TF_ARGS="-parallelism=$PARALLELISM"

log "Destroying terraform configuration"
terraform destroy -force $TF_ARGS && rm -f "$ENVIRONMENT"

exit 0
