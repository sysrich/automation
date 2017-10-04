#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

source  "$DIR/../../misc-tools/functions"

# options
RUN_UPDATE=

NAME="caasp-stack"
OPENRC_FILE=
HEAT_ENVIRONMENT_FILE="heat-environment.yaml.example"
MASTERS=3
WORKERS=2
IMAGE=

# the environment file
ENVIRONMENT=${ENVIRONMENT:-$DIR/../environment.json}

USAGE=$(cat <<USAGE
Usage:

  * Building a cluster

    -u|--update                      Do an update
    -m|--masters             <INT>   Number of masters to build
    -w|--workers             <INT>   Number of workers to build
    -i|--image               <STR>   Image to use

  * Common options

    -o|--openrc             <STR>   Path to an openrc file
    -e|--heat-environment   <STR>   Path to a heat environment file

  * Examples:

  Build a 2 worker cluster

  $0 -w 2 --openrc my-openrc --image CaaSP-1.0.0-GM --name test-stack

USAGE
)

# parse options
while [[ $# > 0 ]] ; do
  case $1 in
    -n|--name)
      NAME="$2"
      shift
      ;;
    -o|--openrc)
      f="$(realpath $2)"
      check_file $f
      OPENRC_FILE="$f"
      shift
      ;;
    -e|--heat-environment)
      f="$(realpath $2)"
      check_file $f
      HEAT_ENVIRONMENT_FILE="$f"
      shift
      ;;
    -m|--masters)
      MASTERS="$2"
      shift
      ;;
    -w|--workers)
      WORKERS="$2"
      shift
      ;;
    -i|--image)
      IMAGE="$2"
      shift
      ;;
    -u|--update)
      RUN_UPDATE=1
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  shift
done

#########################################################################

export CAASP_PROVIDER="openstack-heat"

[ -z "$OPENRC_FILE" ] && error "Option --openrc is required"
[ -z "$IMAGE"       ] && error "Option --image is required"

# Core methods
build_stack() {
  [ -z "$NAME" ] && error "Option --name is required"

  log "Creating Stack"

  # Keep track of the stack name (which Heat enforces as being unique) for
  # later use in commands like delete.
  echo -n "$NAME" > .stack_name

  source $OPENRC_FILE
  openstack stack create --verbose --wait -e $HEAT_ENVIRONMENT_FILE -t caasp-stack.yaml $NAME \
    --parameter master_count=$MASTERS \
    --parameter worker_count=$WORKERS \
    --parameter image=$IMAGE

  log "CaaSP Stack Created with name $NAME"

  $DIR/tools/generate-environment "$NAME"
  gen_ssh_config
  wait_for_velum
}

update_stack() {

  local stack_name=$(cat .stack_name)
  log "Updating Stack with ID $stack_name"

  source $OPENRC_FILE
  openstack stack update --wait \
    -e "$HEAT_ENVIRONMENT_FILE" \
    -t caasp-stack.yaml "$stack_name" \
    --parameter master_count=$MASTERS \
    --parameter worker_count=$WORKERS \
    --parameter image="$IMAGE"

  $DIR/tools/generate-environment "$NAME"
  gen_ssh_config
}

# main
if [ -n "$RUN_UPDATE" ] ; then
	update_stack
else
	build_stack
fi

exit 0
