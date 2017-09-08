
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
        "sshUser" : "root",
        "sshKey" : ssh_key_path,
        "kubernetesHost" : admin_host_ipaddr,
        "minions": []
    }
    # FIXME: this is picking a macaddr    master_ipaddr = available_hosts[1][2]
    for idx, minion in enumerate(available_hosts):
        name, hw_serial, macaddr, ipaddr, machine_id = minion
        d["minions"].append({
           "minionId" : machine_id,
           "index" : idx,
           "fqdn" : hw_serial,
           "addresses" : {
              "privateIpv4" : ipaddr,
              "publicIpv4" : ipaddr,
           }
        })

        if idx == 0:
            d["minions"][-1]["role"] = "admin"
        elif idx == 1:
            d["minions"][-1]["role"] = "master"
        else:
            d["minions"][-1]["role"] = "worker"
            # unneded
            # d["minions"][-1]["proxyCommand"] = "ssh root@{} -W %h:%p".format(master_ipaddr)

    fn = os.path.abspath('environment.json')
    with open(fn, 'w') as f:
        json.dump(d, f, indent=4, sort_keys=True)
    log.info('{} written'.format(fn))
