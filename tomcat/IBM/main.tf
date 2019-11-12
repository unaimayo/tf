#####################################################################
##
##      Created 11/11/19 by ucdpadmin for cloud 304454_unai.mayo. for tomcat
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

provider "ibm" {}

module "camtags" {
  source = "../Modules/camtags"
}

# This will create a new SSH key that will show up under the \
# Devices>Manage>SSH Keys in the SoftLayer console.
resource "ibm_compute_ssh_key" "orpheus_public_key" {
  label      = "Orpheus Public Key"
  public_key = "${var.public_ssh_key}"
}

# Create a new virtual guest using image "ubuntu"
resource "ibm_compute_vm_instance" "ubuntu_small_virtual_guest" {
  hostname                 = "${var.hostname}"
  os_reference_code        = "UBUNTU_16_64"
  domain                   = "${var.domain}"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  disks                    = [25, 10, 20]
  user_metadata            = "{\"value\":\"newvalue\"}"
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.orpheus_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  tags                     = ["${module.camtags.tagslist}"]
}

##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "temp_public_key" {
  label      = "ssh-key-temp"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

#################################
# Execute Ansible playbook
#################################

resource "null_resource" "execute_ansible" {
  depends_on = ["ibm_compute_vm_instance.ubuntu_small_virtual_guest"]

  # Specify the ssh connection
  connection {
    type        = "ssh"
    user        = "${var.ansible_user}"
    password    = "${var.ansible_password}"
    host        = "${var.ansible_host}"
  }

  # Create the Host File for example
  provisioner "file" {
    content = <<EOF
default ansible_host=${ibm_compute_vm_instance.ubuntu_small_virtual_guest.ipv4_address} ansible_user='root' ansible_ssh_private_key_file=/tmp/ssh_key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

    destination = "/tmp/ansible-playbook-host"
  }

  provisioner "file" {
    content = <<EOF
${tls_private_key.ssh.private_key_pem}
EOF

    destination = "/tmp/ssh_key"
  }
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "cd tomcat_playbook && ansible-playbook -i \"/tmp/ansible-playbook-host\" configure-linux-box.yml",
    ]
  }
}