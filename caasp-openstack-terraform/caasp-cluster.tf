variable "auth_url" {}
variable "domain_name" {}
variable "region_name" {}
variable "project_name" {}
variable "user_name" {}
variable "password" {}
variable "image_name" {}
variable "internal_net" {}
variable "external_net" {}
variable "admin_size" {}
variable "master_size" {}
variable "masters" {}
variable "worker_size" {}
variable "workers" {}

provider "openstack" {
  domain_name = "${var.domain_name}"
  tenant_name = "${var.project_name}"
  user_name = "${var.user_name}"
  password = "${var.password}"
  auth_url = "${var.auth_url}"
  insecure = "true"
}

data "template_file" "cloud-init" {
  template = "${file("cloud-init.cls")}"

  vars {
    admin_address = "${openstack_compute_instance_v2.admin.access_ip_v4}"
  }
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "caasp-ssh"
  region     = "${var.region_name}"
  public_key = "${file("ssh/id_caasp.pub")}"
}

resource "openstack_compute_secgroup_v2" "secgroup_base" {
  name        = "caasp-base"
  region      = "${var.region_name}"
  description = "Basic security group for CaaSP"

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 2379
    to_port     = 2379
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_admin" {
  name        = "caasp-admin"
  region      = "${var.region_name}"
  description = "CaaSP security group for admin"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 4505
    to_port     = 4506
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 389
    to_port     = 389
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_master" {
  name        = "caasp-master"
  region      = "${var.region_name}"
  description = "CaaSP security group for masters"

  rule {
    from_port   = 2380
    to_port     = 2380
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 6443
    to_port     = 6444
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 8285
    to_port     = 8285
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 30000
    to_port     = 32768
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 30000
    to_port     = 32768
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "secgroup_worker" {
  name        = "caasp-worker"
  region      = "${var.region_name}"
  description = "CaaSP security group for workers"

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 8080
    to_port     = 8080
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 8081
    to_port     = 8081
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 2380
    to_port     = 2380
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 10250
    to_port     = 10250
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 8285
    to_port     = 8285
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 30000
    to_port     = 32768
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 30000
    to_port     = 32768
    ip_protocol = "udp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "admin" {
  name       = "caasp-admin"
  region     = "${var.region_name}"
  image_name = "${var.image_name}"

  connection {
    private_key = "${file("ssh/id_caasp.pub")}"
  }

  flavor_name = "${var.admin_size}"
  key_pair    = "caasp-ssh"

  network {
    name = "${var.internal_net}"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.secgroup_base.name}",
    "${openstack_compute_secgroup_v2.secgroup_admin.name}"
  ]

  user_data = "${file("cloud-init.adm")}"
}

resource "openstack_networking_floatingip_v2" "admin_ext" {
  pool = "${var.external_net}"
}

resource "openstack_compute_floatingip_associate_v2" "admin_ext_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.admin_ext.address}"
  instance_id = "${openstack_compute_instance_v2.admin.id}"
}

resource "openstack_compute_instance_v2" "master" {
  count      = "${var.masters}"
  name       = "caasp-master${count.index}"
  region     = "${var.region_name}"
  image_name = "${var.image_name}"

  connection {
    private_key = "${file("ssh/id_caasp.pub")}"
  }

  flavor_name = "${var.master_size}"
  key_pair    = "caasp-ssh"

  network {
    name = "${var.internal_net}"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.secgroup_base.name}",
    "${openstack_compute_secgroup_v2.secgroup_master.name}"
  ]

  user_data = "${data.template_file.cloud-init.rendered}"
}

resource "openstack_networking_floatingip_v2" "master_ext" {
  count = "${var.masters}"
  pool  = "${var.external_net}"
}

resource "openstack_compute_floatingip_associate_v2" "master_ext_ip" {
  count       = "${var.masters}"
  floating_ip = "${element(openstack_networking_floatingip_v2.master_ext.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
}

resource "openstack_compute_instance_v2" "worker" {
  count      = "${var.workers}"
  name       = "caasp-worker${count.index}"
  region     = "${var.region_name}"
  image_name = "${var.image_name}"

  connection {
    private_key = "${file("ssh/id_caasp.pub")}"
  }

  flavor_name = "${var.worker_size}"
  key_pair    = "caasp-ssh"

  network {
    name = "${var.internal_net}"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.secgroup_base.name}",
    "${openstack_compute_secgroup_v2.secgroup_worker.name}"
  ]

  user_data = "${data.template_file.cloud-init.rendered}"
}

resource "openstack_networking_floatingip_v2" "worker_ext" {
  count = "${var.workers}"
  pool  = "${var.external_net}"
}

resource "openstack_compute_floatingip_associate_v2" "worker_ext_ip" {
  count       = "${var.workers}"
  floating_ip = "${element(openstack_networking_floatingip_v2.worker_ext.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.worker.*.id, count.index)}"
}


output "ip_admin" {
  value = "${openstack_networking_floatingip_v2.admin_ext.address}"
}

output "ip_masters" {
  value = ["${openstack_networking_floatingip_v2.master_ext.*.address}"]
}

output "ip_workers" {
  value = ["${openstack_networking_floatingip_v2.worker_ext.*.address}"]
}
