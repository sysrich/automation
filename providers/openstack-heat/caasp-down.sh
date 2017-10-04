#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

source  "$DIR/../../misc-tools/functions"

OPENRC_FILE=

USAGE=$(cat <<USAGE
Usage:

  $0         destroy the cluster

USAGE
)

# parse options
while [[ $# > 0 ]] ; do
  case $1 in
    -o|--openrc)
      f="$(realpath $2)"
      check_file $f
      OPENRC_FILE="$f"
      shift
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  shift
done

#######################################################################

export CAASP_PROVIDER="openstack-heat"

[ -z "$OPENRC_FILE" ]  && error "Option --openrc is required"

stack_name=$(cat .stack_name)
log "Deleting Stack with name $stack_name"

source "$OPENRC_FILE"
openstack stack delete --yes --wait "$stack_name"
rm .stack_name
