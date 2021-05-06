#####################################################################
##
##      Created 6/4/18 by ucdpadmin. for ibm
##
#####################################################################

variable "vm_domain" {
  type = "string"
  description = "The domain for the computing instance."
}

variable "vm_dbserver_hostname" {
  type = "string"
  description = "The hostname for the computing instance."
}

variable "vm_datacenter" {
  type = "string"
  description = "The datacenter in which you want to provision the instance. NOTE: If dedicated_host_name or dedicated_host_id is provided then the datacenter should be same as the dedicated host datacenter."
}

variable "vm_os_reference_code" {
  type = "string"
  description = "Generated"
  default = "UBUNTU_16_64"
}

variable "vm_webserver_hostname" {
  type = "string"
  description = "The hostname for the computing instance."
}

# MariaDB
variable "mariadb_password" {
  type = "string"
  description = "Generated"
}

variable "tomcat_home" {
  type = "string"
  description = "Generated"
}

variable "tomcat_admin_user" {
  type = "string"
  description = "Generated"
}

variable "tomcat_admin_password" {
  type = "string"
  description = "Generated"
}

variable "tomcat_version" {
  type = "string"
  description = "Generated"
}

# UCD
variable "ucd_user" {
  type = "string"
  description = "UCD User."
  default = "PasswordIsAuthToken"
}

variable "ucd_password" {
  type = "string"
  description = "UCD Password."
  default = "2ee156b2-1f60-45b6-a1c3-332c5bd095ae"
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

variable "snapshot" {
  type = "string"
  description = "agent name"
}
