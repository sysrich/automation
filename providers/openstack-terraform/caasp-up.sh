#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

source  "$DIR/../misc-tools/functions"

MASTERS=3
WORKERS=2
IMAGE=
INT_NET=
EXT_NET=

TF_COMMAND=${TF_COMMAND:-apply}

# the environment file
ENVIRONMENT=${$ENVIRONMENT:-$DIR/../environment.json}

USAGE=$(cat <<USAGE
USAGE:

  Before running caasp-openstack script use an "openrc.sh" OpenStack file and

     # source openrc.sh

  or manually export following variables

     - OS_AUTH_URL - OpenStack Identity API v3
     - OS_USER_DOMAIN_NAME - OpenStack Domain Name
     - OS_PROJECT_NAME - OpenStack Project Name
     - OS_REGION_NAME - OpenStack Region Name
     - OS_USERNAME - OpenStack User Name
     - OS_PASSWORD - OpenStack User Password

  * Building a cluster

    -m|--masters             <INT>   Number of masters to build
    -w|--workers             <INT>   Number of workers to build
    -i|--image               <STR>   Image to use
    --internal-net           <STR>   Internal net
    --external-net           <STR>   External net

  Some of these values can also be provided in the openstack.tfvars file

<<<
USAGE
)


# parse options
while [[ $# > 0 ]] ; do
  case $1 in
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
    --internal-net)
      INT_NET="$2"
      shift
      ;;
    --external-net)
      EXT_NET="$2"
      shift
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  shift
done

#############################################################

export CAASP_PROVIDER="openstack-terraform"

[ -n "$MASTERS" ] && TF_ARGS="$TF_ARGS -var masters=$MASTERS"
[ -n "$WORKERS" ] && TF_ARGS="$TF_ARGS -var workers=$WORKERS"
[ -n "$IMAGE"   ] && TF_ARGS="$TF_ARGS -var image_name=$IMAGE"
[ -n "$INT_NET" ] && TF_ARGS="$TF_ARGS -var internal_net=$INT_NET"
[ -n "$EXT_NET" ] && TF_ARGS="$TF_ARGS -var external_net=$EXT_NET"

[ -d ssh ] || mkdir ssh

if ! [ -f ssh/id_caasp ]; then
  ssh-keygen -b 2048 -t rsa -f ssh/id_caasp -N ""
fi

# check the env vars are defined
if [ -v $OS_AUTH_URL ] || \
   [ -v $OS_PROJECT_NAME ] || \
   [ -v $OS_USER_DOMAIN_NAME ] || \
   [ -v $OS_USERNAME ] || \
   [ -v $OS_REGION_NAME ]; then
  abort "$USAGE"
fi

echo ""
echo "OpenStack endpoint $OS_AUTH_URL"
echo ""

if [ -v $OS_PASSWORD ]; then
  echo "Please enter your OpenStack Password: "
  read -sr OS_PASSWORD_INPUT
  export OS_PASSWORD=$OS_PASSWORD_INPUT
fi

TF_ARGS="$TF_ARGS \
  -var auth_url=$OS_AUTH_URL \
  -var domain_name=$OS_USER_DOMAIN_NAME \
  -var region_name=$OS_REGION_NAME \
  -var project_name=$OS_PROJECT_NAME \
  -var user_name=$OS_USERNAME \
  -var password=$OS_PASSWORD \
  -var-file=openstack.tfvars"

terraform $TF_COMMAND $TF_ARGS

# TODO: generate the environment.json file


