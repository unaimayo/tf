#####################################################################
##
##      Created 6/5/18 by ucdpadmin. for ibm
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

provider "ibm" {
  version = "~> 0.7"
}

provider "ucd" {
  username       = "${var.ucd_user}"
  password       = "${var.ucd_password}"
  ucd_server_url = "${var.ucd_server_url}"
}


resource "ibm_compute_vm_instance" "vm_instance" {
  cores       = 1
  memory      = 1024
  domain      = "${var.vm_instance_domain}"
  hostname    = "${var.vm_instance_hostname}"
  datacenter  = "${var.vm_instance_datacenter}"
  ssh_key_ids = ["${ibm_compute_ssh_key.ibm_cloud_temp_public_key.id}"]
  os_reference_code = "${var.vm_instance_os_reference_code}"
  provisioner "ucd" {
    agent_name      = "${var.vm_instance_agent_name}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
  connection {
    user = "TODO"
    private_key = "${var.private_key}"
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "ibm_cloud_temp_public_key" {
  label = "ibm-cloud-temp-public-key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

resource "ucd_component_mapping" "C1" {
  component = "C1"
  description = "C1 Component"
  parent_id = "${ucd_agent_mapping.vm_instance_agent.id}"
}

resource "ucd_component_process_request" "C1" {
  component = "C1"
  environment = "${ucd_environment.environment.id}"
  process = "install"
  resource = "${ucd_component_mapping.C1.id}"
  version = "LATEST"
}

resource "ucd_resource_tree" "resource_tree" {
  base_resource_group_name = "Base Resource for environment ${var.environment_name}"
}

resource "ucd_environment" "environment" {
  name = "${var.environment_name}"
  application = "Test"
  base_resource_group ="${ucd_resource_tree.resource_tree.id}"
  component_property {
      component = "C1"
      name = "prop1"
      value = "value1"
      secure = false
  }
}

resource "ucd_agent_mapping" "vm_instance_agent" {
  description = "Agent to manage the vm_instance server"
  agent_name = "${var.vm_instance_agent_name}.${ibm_compute_vm_instance.vm_instance.ipv4_address_private}"
  parent_id = "${ucd_resource_tree.resource_tree.id}"
}