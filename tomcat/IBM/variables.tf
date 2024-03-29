#####################################################################
##
##      Created 11/11/19 by ucdpadmin for cloud 304454_unai.mayo. for tomcat
##
#####################################################################

variable "vm_domain" {
  type = string
  description = "The domain for the computing instance."
  default = "lab.net"
}

variable "vm_datacenter" {
  type = string
  description = "The datacenter in which you want to provision the instance. NOTE: If dedicated_host_name or dedicated_host_id is provided then the datacenter should be same as the dedicated host datacenter."
  default = "ams03"
}

variable "vm_os_reference_code" {
  type = string
  description = "Generated"
  default = "UBUNTU_16_64"
}

variable "vm_webserver_hostname" {
  type = string
  description = "The hostname for the computing instance."
}

variable "tomcat_home" {
  type = string
  description = "Generated"
  default = "/opt/tomcat"
}

variable "tomcat_admin_user" {
  type = string
  description = "Generated"
  default = "tomcat"
}

variable "tomcat_admin_password" {
  type = string
  description = "Generated"
  default = "password"
}

variable "tomcat_version" {
  type = string
  description = "Generated"
  default = "8.5.65"
}

variable "ucd_user" {
  type = string
  description = "UCD user"
  default = "PasswordIsAuthToken"
}

variable "ucd_password" {
  type = string
  description = "UCD password"
  default = "14ee53c0-b64a-495b-81da-373e2f0db1ff"
}

variable "ucd_server_url" {
  type = string
  description = "UCD server URL"
  default = "https://159.8.228.106:8443"
}