# Kubernetes upstream conformance e2e tests for CaaSP cluster

This is automation for Kubernetes upstream end-to-end tests for CaaSP cluster

## Overview

To run upstream conformance Kubernetes tests script has to build first, Docker openSUSE based image with required packages. When Docker image will be ready, it starts Kubernetes e2e conformance tests. Results from e2e tests will be stored into log file 

`/root/e2e-tests-$(date +%F-%H%M%S).log`.

## Usage

### Requirements

In order to run the Kubernetes conformance e2e tests, the CaaSP cluster has to be installed first. After this we have to extract client connection data e.g. kubeconfig, kube-apiserver url and client certificates.

#### Images used by the Kubernetes e2e tests

During running end-to-end tests, Kubernetes try to pull images from Google's registry.

#### Main options

You can either provide your own `kubeconfig` or point the script to the Kubernetes API server URL (both methods are mutually exclusive)

* `-k|--kubeconfig <FILE>`
    Provide a "kubeconfig" (when using certificates, they should be
    specified as `ca.crt`, `admin.crt` or `admin.key`, with dir name
    /root/.kube/<CERT_FILE_NAME>)
* `-u|--url <URL>`
    Kubernetes API server URL (ie, `https://myserver.suse.de:6443`)

#### Certificates

You will have to provide certificates when using a API server that listens at a SSL port.

* `--ca-crt <FILE>`:
    The `ca.crt` file (this option is required)
* `--admin-crt <FILE>`:
    The `admin.crt` file (this option is required)
* `--admin-key <FILE>`:
    The `admin.key` file (this option is required)

#### Examples

```
./e2e-tests --url https://10.162.168.207:6443 \
    --ca-crt ca.crt \
    --admin-crt admin.crt \
    --admin-key admin.key
```
