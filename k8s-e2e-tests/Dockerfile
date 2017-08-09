FROM opensuse:42.3

MAINTAINER Docker Team <docker-devel@suse.de>

RUN zypper ar -fG http://download.opensuse.org/repositories/devel:/CaaSP:/Head:/ControllerNode/openSUSE_Leap_42.3/devel:CaaSP:Head:ControllerNode.repo && zypper --gpg-auto-import-keys ref

RUN zypper -n install git go

RUN zypper -n install etcdctl \
                      kubernetes-client \
                      kubernetes-extra

RUN zypper clean -a

WORKDIR /root

COPY    entrypoint.sh   /root/

ENTRYPOINT ["/root/entrypoint.sh"]
