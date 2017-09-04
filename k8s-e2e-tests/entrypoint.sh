#!/bin/sh

# some notes:
#
# * these tests do not try to pre-pull all the images needed, so you need a lot of
#   bandwidth in order to pull images in time
#

# where the kubeconfig will be generated/copied to
KUBECONFIG_TARGET="/root/.kube/config"

log()        { (>&2 echo ">>> [e2e-tests] $@") ; }
warn()       { log "WARNING: $@" ; }
error()      { log "ERROR: $@" ; exit 1 ; }
abort()      { log "FATAL: $@" ; exit 1 ; }
check_file() { [ -f "$1" ] || abort "File $1 doesn't exist!" ; }

kubeconfig_fix_certs_paths() {
    log "Fixing certificates paths (if provided)"
    sed -i '
        /certificate-authority:/ s/.*/certificate-authority: \/root\/.kube\/ca.crt/
        /client-certificate:/ s/.*/client-certificate: \/root\/.kube\/admin.crt/
        /client-key:/ s/.*/client-key: \/root\/.kube\/admin.key/
    ' $KUBECONFIG_TARGET
}

kubeconfig_gen() {
    check_file /root/.kube/ca.crt
    check_file /root/.kube/admin.key
    check_file /root/.kube/admin.crt

    log "Generating a valid kubeconfig file"
    cat <<EOF > $KUBECONFIG_TARGET
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /root/.kube/ca.crt
    server: $KUBE_API_URL
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: default-admin
  name: default-system
current-context: default-system
kind: Config
preferences: {}
users:
- name: default-admin
  user:
    client-certificate: /root/.kube/admin.crt
    client-key: /root/.kube/admin.key
EOF
}

run_tests() {
    export KUBECONFIG=$KUBECONFIG_TARGET
    export KUBECTL_PATH=/usr/bin/kubectl
    export PATH=$KUBE_ROOT/platforms/linux/amd64:$PATH
    export KUBE_ROOT=/usr/src/kubernetes
    export KUBERNETES_CONFORMANCE_TEST=y
    export E2E_REPORT_DIR=/tmp/artifacts
    export KUBE_TEST_ARGS="\
        -v=5 \
        --alsologtostderr \
        --ginkgo.progress \
        --report-dir=/tmp/artifacts \
        --clean-start=true \
        --dump-logs-on-failure \
        --delete-namespace=true \
        --ginkgo.trace=true \
        --ginkgo.flakeAttempts=3"
        # --ginkgo.flakeAttempts is the time to retry when there is a test failure.

    cd $KUBE_ROOT

    # Compute number of ready Kubernetes cluster nodes
    export K8S_NODES=`kubectl get nodes 2> /dev/null | grep " Ready " | wc -l`
    export GINKGO_PARALLEL=y
    # The number of tests that can be run in parallel depends on
    # size of the Kubernetes cluster and number of worker nodes. 
    # Too many, and tests will fail due to resource contention.
    export GINKGO_PARALLEL_NODES=$K8S_NODES
 
    # first run the parallelizable tests
    env E2E_REPORT_PREFIX=parallel \
    go run hack/e2e.go -v --test \
        --test_args="$KUBE_TEST_ARGS --ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Serial\]" 2>&1 | \
            tee /tmp/e2e-test.log

    # For serial tests we have to set GINKGO_PARALLEL_NODES=1
    export GINKGO_PARALLEL_NODES=1

    # now run the serial tests
    env E2E_REPORT_PREFIX=serial \
    go run hack/e2e.go -v --test \
        --test_args="$KUBE_TEST_ARGS --ginkgo.focus=\[Serial\].*\[Conformance\]" 2>&1 | \
            tee -a /tmp/e2e-test.log
}

# main

mkdir -p "$(dirname $KUBECONFIG_TARGET)"

if [ -n "$KUBE_API_URL" ] ; then
    kubeconfig_gen
elif [ -n "$KUBECONFIG" ] ; then
    # copy the kubeconfig to $KUBECONFIG_TARGET: we cannot modify the host's kubeconfig
    cp -f "$KUBECONFIG" "$KUBECONFIG_TARGET"
    kubeconfig_fix_certs_paths
else
    abort "we need either a --kubeconfig or a --url"
fi

run_tests
