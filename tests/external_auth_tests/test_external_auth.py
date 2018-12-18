import logging
import os

from tests.util.container_tests import ContainerTests

logger = logging.getLogger(name=__file__)


def test_open_ldap(open_ldap_server, dockerfile, results_dir):
    with ContainerTests('open-ldap',
                        results_path=results_dir,
                        path=dockerfile,
                        tag='external-auth-test') as ct:

        ct.start_test('setup',
                      'pytest --junit-xml /results/open-ldap-setup-{}.xml /tests/ldap_tests/test_open_ldap_setup.py'.format(ct.start_time),
                      network='{}_default'.format(open_ldap_server.name),
                      volumes={os.path.dirname(__file__): {'bind': '/tests', 'mode': 'rw'}})
