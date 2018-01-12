
# Create environment.json file - see environment.json.example

import os

import logging
import json

log = logging.getLogger(__name__)

SSH_KEY_RELPATH = "automation/misc-files/id_shared"


def create_environment_json(admin_host_ipaddr, available_hosts):
    """
    First host: admin
    Second host: master
    """
    ws = os.environ.get('WORKSPACE', os.path.expanduser("~"))
    ssh_key_path = os.path.join(ws, SSH_KEY_RELPATH)

    d = {
        "dashboardHost": admin_host_ipaddr,
        "dashboardExternalHost": admin_host_ipaddr,
        "sshUser" : "root",
        "sshKey" : ssh_key_path,
        "minions": []
    }
    # FIXME: this is picking a macaddr    master_ipaddr = available_hosts[1][2]
    for idx, minion in enumerate(available_hosts):
        name, hw_serial, macaddr, ipaddr, machine_id = minion
        if idx == 0:
            role = "admin"
        elif idx == 1:
            role = "master"
            # TODO: This will fail for multi-master, this needs to be a round robin DNS record, or
            # a load balancer address - or at the least - a DNS name aimed at one of the masters and
            # registered in /etc/hosts on any machine who needs to reach the cluster.
            d["kubernetesExternalHost"] = ipaddr
        else:
            role = "worker"

        d["minions"].append({
           "minionId": machine_id,
           "index": idx,
           "fqdn": "{}-{}".format(role, hw_serial),
           "role": role,
           "addresses": {
              "privateIpv4" : ipaddr,
              "publicIpv4" : ipaddr,
           }
        })

    fn = os.path.abspath('environment.json')
    with open(fn, 'w') as f:
        json.dump(d, f, indent=4, sort_keys=True)
    log.info('{} written'.format(fn))
