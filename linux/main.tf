#####################################################################
##
##      Created 12/18/19 by admin. for linux
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

