#####################################################################
##
##      Created 12/16/18 by ucdpadmin. for agbar
##
#####################################################################

#########################################################
# Define the variables
#########################################################

variable "azure_region" {
  description = "Azure region to deploy infrastructure resources"
  default     = "West US"
}

variable "name_prefix" {
  description = "Prefix of names for Azure resources"
  default     = "tomcat"
}

variable "admin_user" {
  description = "Name of an administrative user to be created in virtual machine"
  default     = "ibmadmin"
}

variable "admin_user_password" {
  description = "Password of the newly created administrative user"
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
