# testinfra tests for kubic nodes

This is a collection of testinfra tests that can be used to ensure that the bootstraping 
of a CaaSP install has been completed correctly

## Running tests

This requires python-tox to be installed on your system.

Running `tox` will run the tests against all nodes created by the `kubic-project/caasp-kvm` repository.

It looks for an `environment.json` file in a path `../caasp-kvm/environment.json` - if your file is in a different location, use the `ENVIRONMENT_JSON` enviroment variable to point to it.

`tox -e linters` runs code syntax checks on the tests, and should be ran before a PR is opened

## Development

If you are working on a test for a role, you can run single role tests by running 

`tox -e <role> -- --hosts <ip of node>` where `<role>` is one of admin, worker or master.

## Manually Running

To manually run the tests, you need to do a test run per node type right now in the following form:

```
pytest --ssh-config=~/.ssh/config --sudo --hosts=admin-ip -m "admin or common" --junit-xml admin.xml -v
pytest --ssh-config=~/.ssh/config --sudo --hosts=master-ip -m "master or common" --junit-xml master.xml -v
pytest --ssh-config=~/.ssh/config --sudo --hosts=worker-1-ip,worker-2-ip -m "worker or common" --junit-xml workers.xml -v
```

Where `~/.ssh/config` is an ssh config file that tells ssh what key to use for the connection.

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
