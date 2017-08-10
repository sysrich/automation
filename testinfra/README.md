# testinfra tests for kubic nodes

This is a collection of testinfra tests that can be used to ensure that the bootstraping 
of a CaaSP install has been completed successfully.

## Requirements

You can install the necessary dependancy packages with:

    $ sudo zypper in jq python-tox

The default value for ENVIRONMENT_JSON is `../caasp-kvm/environment.json`, so in many cases, simply
running `tox` will be enough to run the tests.

## Manually Running

To manually run the tests, you need to do a test run per node type right now in the following form:

```
tox -e admin -- --hosts <admin-node-ip>
tox -e master -- --hosts <master-node-ip>
tox -e worker -- --hosts <worker-node-ip>
tox -e worker -- --hosts <worker-node-ip>,<worker-node-ip>
```

## File Structure

Right now, there is 4 test files.

- `tests/test_common.py` - tests for services that are on all nodes, e.g. `etcd`, `salt-minion`
- `tests/test_kubic_admin.py` - tests for services, files and configuration that are on just the admin node, e.g. salt roles
- `tests/test_kubernetes_master.py` - tests for services, files and configuration that are on just the master node, and some tests of the kubernetes cluster itself
- `tests/test_kubernetes_worker.py` - tests for services, files and configuration that are on just the worker nodes

## Related Links:

- testinfra http://testinfra.readthedocs.io/en/latest/index.html
- pytest https://docs.pytest.org/en/latest/contents.html
- tox https://tox.readthedocs.io/en/latest/
