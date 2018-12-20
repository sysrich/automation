import logging
import os

from tests.util.container_info import get_network_by_name
from tests.util.container_tests import ContainerTests

logger = logging.getLogger(name=__file__)


def test_open_ldap(open_ldap_server, dockerfile, results_dir):
    network = get_network_by_name(open_ldap_server, 'default', partial=True)

    with ContainerTests('open-ldap',
                        results_path=results_dir,
                        path=dockerfile,
                        tag='external-auth-test') as ct:

        ct.start_test('setup',
                      'pytest --junit-xml /results/open-ldap-setup-{}.xml /tests/ldap_tests/test_open_ldap_setup.py'.format(ct.start_time),
                      network=network,
                      volumes={os.path.dirname(__file__): {'bind': '/tests', 'mode': 'rw'}})
