#!/bin/bash

zypper -n in -l -y ntp 

cat <<EOF > /etc/ntp.conf
server ntp1.suse.de
server ntp2.suse.de
server ntp3.suse.de
EOF

systemctl start ntpd
systemctl stop SuSEfirewall2

zypper in -l -y docker-distribution-registry

echo "proxy:
  remoteurl: https://registry.suse.com"  >> /etc/registry/config.yml

systemctl enable --now registry.service