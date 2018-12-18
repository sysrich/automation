import datetime
import io
import logging
import os
import tarfile
from collections import namedtuple

import docker

logging.basicConfig()
logger = logging.getLogger(name=__file__)


class ContainerTests:

    def __init__(self, suite_name, results_path=None, **build_args):
        """
        Class for running tests in containers
        :param suite_name: (str)
        :param results_path: (str) Path to where the results should go
        :param build_args: Any additional keyword args are passed to the build step
        """
        self.suite_name = suite_name
        self.start_time = None
        self.end_time = None

        self._client = docker.from_env()
        self._tests = []
        self._results_path = '' if results_path is None else results_path
        self._build_args = build_args

        if self._build_args['tag'] is None:
            self._build_args['tag'] = 'container-test'

        self.__TestContainer = namedtuple('TestContainer', ['name', 'container'])

    def start_test(self, test_name, cmd, **kwargs):
        """
        Start a test container and watch it's output
        :param test_name: The name of the test
        :param cmd: The command that starts the test
        :param kwargs: Any kwargs to pass to the container
        :return:
        """

        log_name = '{}-{}-{}.log'.format(self.suite_name, test_name, self.start_time)

        log_path = os.path.join(self._results_path, log_name)

        container = self._client.containers.run(self._build_args['tag'], command=cmd, detach=True, **kwargs)

        self._tests.append(self.__TestContainer(test_name, container))

        with open(log_path, mode='wb') as f:
            for line in container.logs(stream=True, timestamps=True):
                print(line.decode('utf-8'))
                f.write(line)

    def _cleanup(self):
        extract_path = self._results_path

        if os.path.basename(self._results_path) == 'results':
            extract_path = os.path.dirname(self._results_path)

        for test in self._tests:
            results = test.container.get_archive('/results')

            for item in results[0]:
                tar = tarfile.TarFile(fileobj=io.BytesIO(item))
                tar.extractall(path=extract_path)

            test.container.remove(v=True, force=True)

        self._tests.clear()

    def __enter__(self):
        self.start_time = datetime.datetime.now().isoformat()

        self._client.images.build(**self._build_args)

        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.end_time = datetime.datetime.now().isoformat()

        if exc_type is not None:
            logger.error(exc_type)
            logger.error(exc_val)
            logger.error(exc_tb)
            return False

        self._cleanup()

        return True
