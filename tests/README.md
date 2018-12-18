# Kubic Automation Tests
These tests use py.test to start a docker container that runs the required tests. 
Then the test results are collected and output to `tests/results/` and the container is removed.

This way the tests can be ran in isolated environments and allow our Jenkins workers to be more generic.

# Structure
Right now the structure for the tests is 
    
    tests/
    +-- feature_tests/
    |   +-- specific_feature_tests/ (Like ldap_tests/ for the external auth feature)
    |   +-- conftest.py (For fixtures only needed by this feature)
    |   +-- test_feature.py (Where the different test containers for the feature are started)
    +-- util/ (Shared python modules that can be used by the tests)
    +-- conftest.py (Shared fixtures)
    +-- Dockerfile (Generic docker file to be used for the tests)
    +-- pytest.ini (py.test config file)
    +-- README.md (This file)
    +-- requirements.txt (The python packages required to run these tests)
    
# Running the tests
You can run a feature test with `pytest feature_tests/test_feature.py`. 
Running individual test modules locally is possible depending on if you have it's dependencies installed.

# Future Tests
As more tests get added the idea is that each feature and/or test will have it's own Dockerfile that will exit once the test completes. 
Any results that are at `/results` in the container will then be collected and can be parsed by Jenkins.
Depending on the tests some of them could even be ran in parallel.

# Writing a new feature test

```
def test_my_feature(dockerfile, results_dir):
    with ContainerTests('test-suite-name', results_path=results_dir, path=dockerfile, tag='docker-image-tag') as ct:

        ct.start_test('test-1',
                      'Command to start the test container with',
                      volumes={os.path.dirname(__file__): {'bind': '/tests', 'mode': 'rw'}})
        ct.start_test('test-2',
                      'Other command to start the test container with',
                      volumes={os.path.dirname(__file__): {'bind': '/tests', 'mode': 'rw'}})
```

The `ContainerTests` class is a generator that takes care of building the image, collecting the results and cleaning up the containers.

The `start_test` function uses the Docker run command to run the given command in the container. 
Each time it's used within the context of the generator it will start another container based on the same image.
If you run multiple tests this way make sure to give them different names since it's used to name the log file.
