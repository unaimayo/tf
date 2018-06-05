#####################################################################
##
##      Created 6/5/18 by ucdpadmin. for ibm
##
#####################################################################

variable "vm_instance_domain" {
  type = "string"
  description = "The domain for the computing instance."
}

variable "vm_instance_hostname" {
  type = "string"
  description = "The hostname for the computing instance."
}

variable "vm_instance_datacenter" {
  type = "string"
  description = "The datacenter in which you want to provision the instance. NOTE: If dedicated_host_name or dedicated_host_id is provided then the datacenter should be same as the dedicated host datacenter."
}

variable "vm_instance_os_reference_code" {
  type = "string"
  description = "Generated"
}

variable "ucd_user" {
  type = "string"
  description = "UCD User."
  default = "PasswordIsAuthToken"
}

variable "ucd_password" {
  type = "string"
  description = "UCD Password."
  default = ""
}

variable "ucd_server_url" {
  type = "string"
  description = "UCD Server URL."
  default = "https://159.8.228.106:8443"
}

variable "environment_name" {
  type = "string"
  description = "Generated"
}

variable "prop1" {
  type = "string"
  description = "Generated"
}

variable "vm_instance_agent_name" {
  type = "string"
  description = "agent name"
}

