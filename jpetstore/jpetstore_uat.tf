#####################################################################
##
##      Created 2/7/18 by ucdpadmin.
##
#####################################################################

terraform {
  required_version = "> 0.7.0"
}

provider "ibm" {
}

variable "tomcat_virtual_guest_number_of_cores" {
  type = "string"
  description = "Generated"
}

variable "local_disk" {
  type = "string"
  description = "Generated"
}

variable "tomcat_virtual_guest-name" {
  type = "string"
  description = "Generated"
}

variable "tomcat_virtual_guest_memory" {
  type = "string"
  description = "Generated"
}

variable "tomcat_virtual_guest_datacenter" {
  type = "string"
  description = "Generated"
}

variable "tomcat_virtual_guest-image" {
  type = "string"
  description = "Generated"
}

variable "domain_name" {
  type = "string"
  description = "Generated"
}

variable "tomcat_virtual_guest_hourly_billing" {
  type = "string"
  description = "Generated"
}

variable "tomcat_ssh_keys" {
  type = "string"
  description = "Generated"
}

variable "mysql_virtual_guest_number_of_cores" {
  type = "string"
  description = "Generated"
}

variable "mysql_virtual_guest-name" {
  type = "string"
  description = "Generated"
}

variable "mysql_virtual_guest_memory" {
  type = "string"
  description = "Generated"
}

variable "mysql_virtual_guest_datacenter" {
  type = "string"
  description = "Generated"
}

variable "mysql_virtual_guest-image" {
  type = "string"
  description = "Generated"
}

variable "mysql_virtual_guest_hourly_billing" {
  type = "string"
  description = "Generated"
}

variable "mysql_ssh_keys" {
  type = "string"
  description = "Generated"
}

variable "agent_name" {
  type = "string"
  description = "Generated"
}

variable "ucd_server_url" {
  type = "string"
  description = "Generated"
}

variable "ucd_user" {
  type = "string"
  description = "Generated"
}

variable "ucd_password" {
  type = "string"
  description = "Generated"
}

data "softlayer_ssh_key" "public_key" {
    label = "${var.tomcat_ssh_keys}"
}

resource "softlayer_virtual_guest" "tomcat" {
  cpu="${var.tomcat_virtual_guest_number_of_cores}"
  local_disk = "${var.local_disk}"
  name="${var.tomcat_virtual_guest-name}"
  ram="${var.tomcat_virtual_guest_memory}"
  region="${var.tomcat_virtual_guest_datacenter}"
  image="${var.tomcat_virtual_guest-image}"
  domain = "${var.domain_name}"
  hourly_billing = "${var.tomcat_virtual_guest_hourly_billing}"
  ssh_keys = ["${data.softlayer_ssh_key.public_key.id}"]
  provisioner "ucd" {
    agent_name      = "${var.agent_name}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
}

resource "softlayer_virtual_guest" "mysql" {
  cpu="${var.mysql_virtual_guest_number_of_cores}"
  local_disk = "${var.local_disk}"
  name="${var.mysql_virtual_guest-name}"
  ram="${var.mysql_virtual_guest_memory}"
  region="${var.mysql_virtual_guest_datacenter}"
  image="${var.mysql_virtual_guest-image}"
  domain = "${var.domain_name}"
  hourly_billing = "${var.mysql_virtual_guest_hourly_billing}"
  ssh_keys = ["${var.mysql_ssh_keys}"]
  provisioner "ucd" {
    agent_name      = "${var.agent_name}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
}