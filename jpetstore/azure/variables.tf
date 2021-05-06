#####################################################################
##
##      Created 5/5/21 by ucdpadmin for cloud azure_mapfre. for azure
##
#####################################################################

variable "azurerm_network_address_space" {
  type = string
  description = "Generated"
  default = "10.0.0.0/16"
}

variable "webserver_name" {
  type = string
  description = "Generated"
  default = "az-tomcat-mapfre"
}

variable "vm_location" {
  type = string
  description = "Generated"
  default = "West Europe"
}


variable "webserver_azure_user" {
  type = string
  description = "Generated"
  default = "ibmadmin"
}

variable "webserver_azure_user_password" {
  type = string
  description = "Generated"
  default = "Passw0rd.muy.segura"
}

variable "address_prefix" {
  type = string
  description = "Generated"
  default = "10.0.1.0/24"
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
  default = "eb0fa012-b3a3-4f71-ad29-476b58d27ba7"
}

variable "ucd_server_url" {
  type = string
  description = "UCD server URL"
  default = "https://159.8.228.106:8443"
}

variable "ucd_environment" {
  type = string
  description = "Environment name"
  default = "DEV"
}

variable "resource_group_name" {
  type = string
  description = "Generated"
  default = "jpetstore_group"
}


