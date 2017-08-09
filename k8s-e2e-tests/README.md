# Kubernetes upstream conformance e2e tests for CaaSP cluster

This is automation for Kubernetes upstream end-to-end tests for CaaSP cluster

## Overview

To run upstream conformance Kubernetes tests `e2e-tests` script has to build Docker openSUSE based image with required packages. When Docker image will be ready, it starts Kubernetes e2e conformance tests. Results from e2e tests will be stored into log file. 

## Usage

### Requirements

In order to run the Kubernetes conformance e2e tests, the CaaSP cluster has to be installed first. After installation `kubeconfig` has to be to extracted on machine where tests will be started.

#### Steps to run Kubernetes end-to-end tests

1. Download `kubeconfig`, on machine where would you like to run k8s end-to-end tests.

2. Clone automation repository on the test machine
```
git clone https://github.com/kubic-project/automation
```

3. Go into run directory
```
cd automation/k8s-e2e-tests
```

4. Run tests by following command
```
./e2e-tests -k <path_to_kubeconfig> --log /tmp/e2e-tests.log
```

5. Wait until tests will ends, results will be stored into /tmp/e2e-tests.log 

#### Images used by the Kubernetes e2e tests

During running end-to-end tests, Kubernetes try to pull images from Google's registry.

#### Main options

You can either provide your own `kubeconfig` or point the script to the Kubernetes API server URL (both methods are mutually exclusive)

* `-k|--kubeconfig <FILE>`
    When "kubeconfig" is provided without certificates, they should be
    embedded.
* `-u|--url <URL>`
    Kubernetes API server URL (ie, `https://myserver.suse.de:6443`)

#### Certificates

You will have to provide certificates when using a API server that listens at a SSL port.

* `--ca-crt <FILE>`:
    The `ca.crt` file (this option is required with --url)
* `--admin-crt <FILE>`:
    The `admin.crt` file (this option is required with --url)
* `--admin-key <FILE>`:
    The `admin.key` file (this option is required with --url)

#### Examples

```
./e2e-tests -k /root/kubeconfig --log /tmp/e2e-tests.log
```
