#####################################################################
##
##      Created 2/7/18 by ucdpadmin.
##
#####################################################################

terraform {
  required_version = "> 0.7.0"
}

provider "aws" {
  access_key = "${var.aws_access_id}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

variable "aws_access_id" {
  type = "string"
  description = "Generated"
}

variable "aws_secret_key" {
  type = "string"
  description = "Generated"
}

variable "region" {
  type = "string"
  description = "Generated"
}

variable "ami" {
  type = "string"
  description = "Generated"
}

variable "key_name" {
  type = "string"
  description = "Generated"
}

variable "aws_instance_type" {
  type = "string"
  description = "Generated"
}

variable "dbserver_availability_zone" {
  type = "string"
  description = "Generated"
}

variable "dbserver_name" {
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

resource "aws_instance" "dbserver" {
  ami = "${var.ami}"
  key_name = "${var.key_name}"
  instance_type = "${var.aws_instance_type}"
  availability_zone = "${var.dbserver_availability_zone}"
  provisioner "ucd" {
    agent_name      = "${var.agent_name}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
  tags {
    Name = "${var.dbserver_name}"
  }
}