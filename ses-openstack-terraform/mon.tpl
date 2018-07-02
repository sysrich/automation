#!/bin/bash

SUSEConnect -r ${regcode}
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${ses_base} ses_base
zypper --non-interactive --quiet --gpg-auto-import-keys ar -f ${ses_update} ses_update

zypper -n in -l -y ntp 

cat <<EOF > /etc/ntp.conf
server ntp1.suse.de
server ntp2.suse.de
server ntp3.suse.de
EOF

cat <<EOF > /etc/ntp.conf
server ntp1.suse.de
server ntp2.suse.de
server ntp3.suse.de
EOF

a=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | awk '{gsub ( "[.]","-" ) ; print "host-"$0 }')

cat <<EOF > /etc/hostname
$a
EOF

hostnamectl set-hostname $a

/usr/bin/systemctl stop SuSEfirewall2.service
/usr/bin/systemctl enable --now ntpd.service

zypper -n in -l -y salt-minion

cat <<EOF > /etc/salt/minion.d/master.conf
master: ${saltmaster}
EOF

systemctl enable salt-minion.service
systemctl start salt-minion.service
