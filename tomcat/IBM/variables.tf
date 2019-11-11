#####################################################################
##
##      Created 11/11/19 by ucdpadmin for cloud 304454_unai.mayo. for tomcat
##
#####################################################################

variable "public_ssh_key" {
  description = "Public SSH key used to connect to the virtual guest"
}

variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}

variable "hostname" {
  description = "Hostname of the virtual instance (small flavor) to be deployed"
  default     = "debian-small"
}

variable "domain" {
  description = "VM domain"
}

variable "ansible_host" {
  description = "Ansible host"
}

variable "ansible_user" {
  description = "Ansible user"
}

variable "ansible_password" {
  description = "Ansible user password"
}
