#####################################################################
##
##      Created 6/4/18 by ucdpadmin. for aws
##
#####################################################################

variable "ami" {
  type = "string"
  description = "Generated" 
  # Ubuntu 16.04 eu-central-1 ami
  default = "ami-5055cd3f"
}

variable "aws_instance_type" {
  type = "string"
  description = "Generated"
}

variable "key_pair_name" {
  type = "string"
  description = "Key pair to be created"
}

variable "dbserver_name" {
  type = "string"
  description = "Generated"
}

variable "mariadb_password" {
  type = "string"
  description = "Generated"
}

variable "webserver_name" {
  type = "string"
  description = "Generated"
}

variable "tomcat_home" {
  type = "string"
  description = "Generated"
}

variable "tomcat_port" {
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

variable "aws_vpc_name" {
  type = "string"
  description = "Generated"
}

variable "environment_name" {
  type = "string"
  description = "Generated"
}
