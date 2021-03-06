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

data "ibm_compute_ssh_key" "unai_public_key" {
    label = "unai"
}

# Create a new virtual guest using image "ubuntu"
resource "ibm_compute_vm_instance" "ubuntu_small_virtual_guest" {
  hostname                 = "${var.hostname}"
  os_reference_code        = "CENTOS_7_64"
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
  ssh_key_ids              = ["${data.ibm_compute_ssh_key.unai_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
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

