import os

import pytest


def pytest_addoption(parser):
    parser.addoption('--dockerfile',
                     action='store',
                     default=os.path.join(os.path.dirname(__file__), 'Dockerfile'),
                     help='Path to the Dockerfile to run the test in.')


@pytest.fixture(scope='session')
def dockerfile(request):
    dockerfile_path = request.config.getoption('--dockerfile')

    if not os.path.isdir(dockerfile_path):
        dockerfile_path = os.path.dirname(dockerfile_path)

    return dockerfile_path


@pytest.fixture(scope='session', autouse=True)
def results_dir():
    results_dir_path = os.path.join(os.path.dirname(__file__), 'results')
    if not os.path.isdir(results_dir_path):
        os.mkdir(results_dir_path)

    return results_dir_path
