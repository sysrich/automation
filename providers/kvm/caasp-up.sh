#!/bin/sh

set -euo pipefail

DIR="$( cd "$( dirname "$0" )" && pwd )"

source  "$DIR/../../misc-tools/functions"

################################################################

MASTERS=${CAASP_NUM_MASTERS:-1}
WORKERS=${CAASP_NUM_WORKERS:-2}
IMAGE=${CAASP_IMAGE:-channel://devel}
PROXY=${CAASP_HTTP_PROXY:-}
PARALLELISM=${CAASP_PARALLELISM:-1}

CAASP_SALT_DIR=${CAASP_SALT_DIR:-$DIR/../../salt}
CAASP_MANIFESTS_DIR=${CAASP_MANIFESTS_DIR:-$DIR/../../caasp-container-manifests}
CAASP_VELUM_DIR=${CAASP_VELUM_DIR:-$DIR/../../velum}

# the environment file
ENVIRONMENT=${ENVIRONMENT:-$DIR/../environment.json}

USAGE=$(cat <<USAGE
Usage:

  * Building a cluster

    -m|--masters <INT>     Number of masters to build (Default: CAASP_NUM_MASTERS=$MASTERS)
    -w|--workers <INT>     Number of workers to build (Default: CAASP_NUM_WORKERS=$WORKERS)
    -i|--image <STR>       Image to use (Default: CAASP_IMAGE=$IMAGE)

  * Common options

    -p|--parallelism       Set terraform parallelism (Default: CAASP_PARALLELISM)
    -P|--proxy             Set HTTP proxy (Default: CAASP_HTTP_PROXY)

  * Local git checkouts

     --salt-dir <DIR>      the Salt repo checkout (Default: CAASP_SALT_DIR)
     --manifests-dir <DIR> the manifests repo checkout (Default: CAASP_MANIFESTS_DIR)
     --velum-dir <DIR>     the Velum repo checkout (Default: CAASP_VELUM_DIR)

  * Examples:

  Build a 1 master, 2 worker cluster

  $0 -m 1 -w 2

  Build a 1 master, 2 worker cluster using the latest staging A image

  $0 -m 1 -w 2 --image channel://staging_a

  Destroy a cluster

  $0 --destroy

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
    -p|--parallelism)
      PARALLELISM="$2"
      shift
      ;;
    -P|--proxy)
      PROXY="$2"
      shift
      ;;
    --salt-dir)
      CAASP_SALT_DIR="$2"
      shift
      ;;
    --manifests-dir)
      CAASP_MANIFESTS_DIR="$2"
      shift
      ;;
    --velum-dir)
      CAASP_VELUM_DIR="$2"
      shift
      ;;
    -h|--help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  shift
done

################################################################

export CAASP_PROVIDER="kvm"

TF_ARGS="-parallelism=$PARALLELISM \
         -var caasp_img_source_url=$IMAGE \
         -var caasp_master_count=$MASTERS \
         -var caasp_worker_count=$WORKERS"

if [ -n "$CAASP_SALT_DIR" ] ; then
  CAASP_SALT_DIR="$(realpath $CAASP_SALT_DIR)"
  TF_ARGS="$TF_ARGS -var kubic_salt_dir=$CAASP_SALT_DIR"
  log "Using Salt dir: $CAASP_SALT_DIR"
fi

if [ -n "$CAASP_VELUM_DIR" ] ; then
  CAASP_VELUM_DIR="$(realpath $CAASP_VELUM_DIR)"
  TF_ARGS="$TF_ARGS -var kubic_velum_dir=$CAASP_VELUM_DIR"
  log "Using Velum dir: $CAASP_VELUM_DIR"
fi

if [ -n "$CAASP_MANIFESTS_DIR" ] ; then
  CAASP_MANIFESTS_DIR="$(realpath $CAASP_MANIFESTS_DIR)"
  TF_ARGS="$TF_ARGS -var kubic_caasp_container_manifests_dir=$CAASP_MANIFESTS_DIR"
  log "Using Manifests dir: $CAASP_MANIFESTS_DIR"
fi

# Core methods
log "CaaS Platform Building"

log "Downloading CaaSP KVM Image"
$DIR/../misc-tools/download-image --proxy "${PROXY}" --type kvm $IMAGE

if [ -n "$CAASP_VELUM_DIR" ] ; then
  log "Building Velum Development Image"
  $DIR/tools/build-velum-image "$CAASP_VELUM_DIR" "${PROXY}"

  log "Creating Velum Directories"
  mkdir -p "$CAASP_VELUM_DIR/tmp" "$CAASP_VELUM_DIR/log" "$CAASP_VELUM_DIR/vendor/bundle"

  log "Copying CaaSP Container Manifests"
  injected="$(realpath injected-caasp-container-manifests)"
  rm -rf $injected/*
  cp -r $CAASP_MANIFESTS_DIR/* "$injected/"

  log "Patching Container Manifests"
  $DIR/tools/fix-kubelet-manifest -o $injected/public.yaml $injected/public.yaml
else
  log "Skipping Velum environment"
fi

log "Applying terraform configuration"
terraform apply $TF_ARGS

$DIR/tools/generate-environment
gen_ssh_config
wait_for_velum

log "CaaS Platform Ready for bootstrap"

exit 0

