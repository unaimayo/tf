##############################################################################
# This sample is provided as-is and should be used only for testing          #
# purposes.                                                                  #
#                                                                            #
# This sample requires that you have                                         #
#                                                                            #
#  1. An UrbanCode Deploy Server                                             #
#  2. Your UrbanCode Deploy Server is directly accessible from               #
#     the Terraform runtime server                                           #
#  3. An AWS access id and secret key                                        #
#                                                                            #
# This sample configuration will                                             #
#                                                                            #
#  1. create a new public/private key                                        #
#  2. create a new AWS key pair for this public key                          #
#  3. launch a t2.small ubuntu server from ami ami-f4cc1de2                  #
#  4. install a UrbanCode Deploy agent on this server                        #
#  5. create a base resource in UrbanCode deploy and map this agent into it  #
#                                                                            #
##############################################################################


##############################################################################
#                                 Variables                                  #
##############################################################################

#####################
#  AWS Information  #
#####################
variable "region" {
  description = "The AWS region for provisioning."
  default = "us-east-1"
}

# ubuntu 16_04
variable "ami" {
  description = "AWS image to provision."
  default = "ami-f4cc1de2"
}

variable "key_pair_name" {
  description = "The name of the AWS key pair to create."
}

#####################
#  UCD Information  #
#####################
variable "ucd_server_url" {
  description = "The UrbanCode Deploy Server URL in the form http://server:port"
}

variable "ucd_user" {
  description = "An UrbanCode Deploy user"
}

variable "ucd_password" {
  description = "The UrbanCode Deploy users password"
}

variable "base_resource_group_name" {
  description = "The base resource group to create in UrbanCode Deploy for this environment"
  default = "provider-test-base-resource-group"
}

variable "server_agent_name" {
  description = "The name of the UrbanCode Deploy Agent and the database VM in AWS"
  default = "ucd-provider-agent"
}

##############################################################################
#                                 Providers                                  #
##############################################################################
provider "ucd" {
  username       = "${var.ucd_user}"
  password       = "${var.ucd_password}"
  ucd_server_url = "${var.ucd_server_url}"
}
provider "aws" {
}

##############################################################################
#                                 Resources                                  #
##############################################################################

################################################
# Create an SSH key pair to connect to servers #
################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

################################################
# Create a keypair for the new private key     #
################################################
resource "aws_key_pair" "internal_key" {
  key_name   = "${var.key_pair_name}"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

################################################
# Create the server with a UCD agent           #
################################################
resource "aws_instance" "ucd-provider-test-server" {

  instance_type = "t2.small"
  ami = "${var.ami}"
  key_name = "${aws_key_pair.internal_key.id}"
  tags {
      Name = "${var.server_agent_name}"
  }

  connection {
    user = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }

  provisioner "ucd" {
    agent_name      = "${var.server_agent_name}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
    agent_team      = ""
  }
}

################################################
# Add the agent to the resource tree        #
################################################
resource "ucd_agent_mapping" "server_agent" {
  agent_name = "${var.server_agent_name}.${aws_instance.ucd-provider-test-server.private_ip}"
  description = "Agent to manage the database server"
  parent_id = "${ucd_resource_tree.provider-test-tree.id}"
}

################################################
# Create the base resource in UCD              #
################################################
resource "ucd_resource_tree" "provider-test-tree" {
  base_resource_group_name = "${var.base_resource_group_name}"
}

##############################################################################
#                                  Outputs                                   #
##############################################################################
output "server_public_ip" {
  value = "http://${aws_instance.ucd-provider-test-server.public_ip}"
}
