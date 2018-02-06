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

cd /etc/registry; openssl req \
                  -newkey rsa:2048 -nodes -keyout domain.key -x509 -days 365 -out domain.crt \
                  -subj "/C=DE/ST=Bayern/L=Nuremberg/O=SUSE Linux/OU=IT QA-CSS/CN=suse-registry-mirror"

echo "  tls:
    certificate: /etc/registry/domain.crt
    key: /etc/registry/domain.key
proxy:
  remoteurl: https://registry.suse.com"  >> /etc/registry/config.yml

systemctl enable --now registry.service