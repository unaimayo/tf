#####################################################################
##
##      Created 2/7/18 by ucdpadmin.
##
#####################################################################

terraform {
  required_version = "> 0.7.0"
}

provider "aws" {
}

##> Parameters
variable "ami" {
  type = "string"
  description = "Generated" 
  # Centos 7 eu-central-1 ami
  default = " ami-337be65c"
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

variable "aws_vpc_name" {
  type = "string"
  description = "Generated"
}

data "aws_vpc" "selected_vpc" {
  filter {
    name = "tag:Name"
    values = ["${var.aws_vpc_name}"]
  }
}

##> SSL
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "internal_key" {
  key_name   = "${var.key_pair_name}"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##> DB Server
resource "aws_instance" "dbserver" {
  ami = "${var.ami}"
  key_name = "${aws_key_pair.internal_key.id}"
  instance_type = "${var.aws_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.mysql.id}"]
  provisioner "file" {
    content = <<EOF
#!/bin/bash
LOGFILE="/var/log/addkey.log"
PASSWORD=$1
yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

EOF

    destination = "/tmp/install_mariadb.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_mariadb.sh; sudo bash /tmp/install_mariadb.sh \"${var.mariadb_password}\"",
    ]
  }
 
  tags {
    Name = "${var.dbserver_name}"
  }
}

resource "aws_security_group" "mysql" {
  name = "mysql"
  description = "TODO"
  vpc_id = "${data.aws_vpc.selected_vpc.id}"
  ingress {
    from_port = 2000
    to_port = 5010
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "mysql"
  }
}

