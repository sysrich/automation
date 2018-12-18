import docker
import pytest


@pytest.mark.open_ldap
class TestLdapConnector:

    @pytest.fixture(scope='class')
    def velum_container(self):
        client = docker.from_env()
        containers = client.list(filters={'name': 'velum-dashboard'})

        return containers[0]

    def test_velum_feature(self, velum_container):
        pytest.fail('Not Implemented')
        # results = velum_container.exec_run('entrypoint.sh bash -c "RAILS_ENV=test '
        #                                    'bundle exec rspec spec/features/dex_connector_ldap_feature_spec.rb"')
        #
        # with open('results/velum_container.log', 'w') as f:
        #     f.write(results[1])
        #
        # assert results[0] == 0
        #
        # with open('results/rspec_results.tar', 'wb') as f:
        #     stream = velum_container.get_archive('/srv/velum/public/coverage')
        #     for chunk in stream:
        #         f.write(chunk)
