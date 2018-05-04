#####################################################################
##
##      Created 5/3/18 by ucdpadmin. for sample1
##
#####################################################################

variable "vm1_domain" {
  type = "string"
  description = "The domain for the computing instance."
}

variable "vm1_hostname" {
  type = "string"
  description = "The hostname for the computing instance."
}

variable "vm1_datacenter" {
  type = "string"
  description = "The datacenter in which you want to provision the instance. NOTE: If dedicated_host_name or dedicated_host_id is provided then the datacenter should be same as the dedicated host datacenter."
}

variable "vm1_os_reference_code" {
  type = "string"
  description = "Generated"
}

variable "ibm_network_public_vlan_id" {
  type = "string"
  description = "Generated"
}

variable "ibm_network_private_vlan_id" {
  type = "string"
  description = "Generated"
}

