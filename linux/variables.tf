#####################################################################
##
##      Created 12/18/19 by admin. for linux
##
#####################################################################

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
