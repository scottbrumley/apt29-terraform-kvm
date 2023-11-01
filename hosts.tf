# Defining VM Volume
resource "libvirt_volume" "ubuntu22-04-qcow2" {
  name = "ubuntu22.04.qcow2"
  pool = "default" # List storage pools using virsh pool-list

  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

  source = "/mnt/lab/images/noble-server-cloudimg-amd64.img"
  format = "qcow2"
}

data "template_file" "user_data"{
  template = file("${path.module}/cloud_init.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = "${data.template_file.user_data.rendered}"
  pool           = "default"
}

### Hosts
# Define KVM domain to create
resource "libvirt_domain" "teamserver" {
  name   = "teamserver"
  memory = "4096"
  vcpu   = 2

  network_interface {
    network_name = "snet-attacker" # List networks with virsh net-list
    hostname = "teamserver"
    addresses = ["192.168.0.4"]
  }

  disk {
    volume_id = "${libvirt_volume.ubuntu22-04-qcow2.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
output "ip" {
  value = "${libvirt_domain.teamserver.network_interface.0.addresses.0}"
}
