#!/bin/sh

kubeconfig_certs_paths() {
    sed -i '
        /certificate-authority:/ s/.*/certificate-authority: \/root\/.kube\/ca.crt/
        /client-certificate:/ s/.*/client-certificate: \/root\/.kube\/admin.crt/
        /client-key:/ s/.*/client-key: \/root\/.kube\/admin.key/
    ' /root/.kube/config

}

kubeconfig_gen() {
    mkdir -p /root/.kube
    cat <<EOF > /root/.kube/config
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

deploy_kube_dns() {
    kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-services/master/contrib/addons/kubedns/dns.yaml
}

run_tests() {
    export KUBECONFIG=/root/.kube/config
    export KUBECTL_PATH=/usr/bin/kubectl
    export PATH=$KUBE_ROOT/platforms/linux/amd64:$PATH
    export KUBE_ROOT=/usr/src/kubernetes
    export KUBERNETES_CONFORMANCE_TEST=y
    export E2E_REPORT_DIR=/tmp/artifacts
    export KUBE_TEST_ARGS="\
        -v=5 \
        --alsologtostderr \
        --ginkgo.progress \
        --e2e-verify-service-account=false \
        --report-dir=/tmp/artifacts \
        --clean-start=true \
        --dump-logs-on-failure \
        --delete-namespace=true \
        --ginkgo.trace=true"

    cd $KUBE_ROOT

    # first run the parallelizable tests
    env GINKGO_PARALLEL=y E2E_REPORT_PREFIX=parallel \
    go run hack/e2e.go -v --test \
        --test_args="$KUBE_TEST_ARGS --ginkgo.focus=\[Conformance\] --ginkgo.skip=\[Serial\]" 2>&1 | \
            tee /tmp/e2e-test.log

    # now run the serial tests
    env E2E_REPORT_PREFIX=serial \
    go run hack/e2e.go -v --test \
        --test_args="$KUBE_TEST_ARGS --ginkgo.focus=\[Serial\].*\[Conformance\]" 2>&1 | \
            tee -a /tmp/e2e-test.log
}

# main
if [ -n "$KUBE_API_URL" ] ; then
    kubeconfig_gen
elif [ -n "$KUBECONFIG" ] ; then
    kubeconfig_certs_paths
else
    abort "we need either a --kubeconfig or a --url"
fi

deploy_kube_dns

run_tests
