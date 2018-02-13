# Copyright 2017 SUSE LINUX GmbH, Nuernberg, Germany.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import pytest


@pytest.mark.etcd
class TestEtcd(object):
    # Tests nodes which have the "etcd" role
    @pytest.mark.parametrize("service", [
        "etcd",
    ])
    def test_services_running(self, host, service):
        host_service = host.service(service)
        assert host_service.is_running

    @pytest.mark.parametrize("service", [
        "etcd",
    ])
    def test_services_enabled(self, host, service):
        host_service = host.service(service)
        assert host_service.is_enabled

    def test_salt_role(self, host):
        assert 'etcd' in host.salt("grains.get", "roles")

    def test_salt_id(self, host):
        machine_id = host.file('/etc/machine-id').content_string.rstrip()
        assert machine_id in host.salt("grains.get", "id")

    def test_etcd_aliveness(self, host):
        hostname = host.file('/etc/hostname').content_string.rstrip()

        cmd = "etcdctl --ca-file /etc/pki/trust/anchors/SUSE_CaaSP_CA.crt "\
              "--key-file /etc/pki/minion.key "\
              "--cert-file /etc/pki/minion.crt "\
              "--endpoints='https://%s:2379' "\
              "cluster-health" % hostname

        # TODO: Switch back to run_expect once we remove compatibility for
        #       our generated hostnames.
        health = host.run(cmd)

        return "cluster is healthy" in health.stdout
