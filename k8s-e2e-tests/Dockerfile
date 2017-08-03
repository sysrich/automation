FROM opensuse:42.1

MAINTAINER Docker Team <docker-devel@suse.de>

RUN zypper ar -fG http://download.suse.de/ibs/SUSE:/SLE-12-SP2:/Update:/Products:/CASP10/standard CASP10 && zypper --gpg-auto-import-keys ref

RUN zypper -n install git go

RUN zypper -n install etcdctl \
                      kubernetes-client \
                      kubernetes-extra

RUN zypper clean -a

WORKDIR /root

COPY    entrypoint.sh   /root/

ENTRYPOINT ["/root/entrypoint.sh"]
