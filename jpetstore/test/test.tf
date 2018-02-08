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

provider "ucd" {
  username       = "${var.ucd_user}"
  password       = "${var.ucd_password}"
  ucd_server_url = "${var.ucd_server_url}"
}

##> Parameters
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

variable "aws_vpc_name" {
  type = "string"
  description = "Generated"
}

variable "environment_name" {
  type = "string"
  description = "Generated"
}

variable "agent_name" {
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

variable "ucd_server_url" {
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
  
  connection {
    user = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }
  
  provisioner "file" {
    content = <<EOF
#!/bin/bash
LOGFILE="/var/log/addkey.log"
PASSWORD=$1

fail() {
  REASON=${1=error}
  echo $REASON | tee -a $LOGFILE 2>&1
  exit 1
}

apt-get update
apt-get install mariadb-server mariadb-client -y
systemctl start mysql
systemctl enable mysql
echo -e "\n\n$PASSWORD\n$PASSWORD\n\n\nn\n\n " | mysql_secure_installation 2>/dev/null

cat << EOT > createdb.sql
create database jpetstore;
create user 'jpetstore'@'localhost' identified by 'jppwd';
grant all privileges on jpetstore.* to 'jpetstore'@'%' identified by 'jppwd';
EOT
mysql -p$PASSWORD < createdb.sql

EOF

    destination = "/tmp/install_mariadb.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_mariadb.sh; sudo bash /tmp/install_mariadb.sh \"${var.mariadb_password}\"",
    ]
  }
  
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

resource "ucd_component_mapping" "JPetStore_DB" {
  component = "JPetStore-DB"
  description = "JPetStore-DB Component"
  parent_id = "${ucd_agent_mapping.dbserver_agent.id}"
}

resource "ucd_component_process_request" "JPetStore_DB" {
  component = "JPetStore-DB"
  environment = "${ucd_environment.environment.id}"
  process = "Deploy DB Component"
  resource = "${ucd_component_mapping.JPetStore_DB.id}"
  version = "2.0"
}

resource "ucd_resource_tree" "resource_tree" {
  base_resource_group_name = "Base Resource for environment ${var.environment_name}"
}

resource "ucd_environment" "environment" {
  name = "${var.environment_name}"
  application = "JPetStore"
  base_resource_group ="${ucd_resource_tree.resource_tree.id}"
  component_property {
      component = "JPetStore-DB"
      name = "db.password"
      value = ""
      secure = true
  }
  component_property {
      component = "JPetStore-DB"
      name = "db.user"
      value = "jpetstore"
      secure = false
  }
  
}

resource "ucd_agent_mapping" "dbserver_agent" {
  description = "Agent to manage the dbserver server"
  agent_name = "${var.agent_name}.${aws_instance.dbserver.private_ip}"
  parent_id = "${ucd_resource_tree.resource_tree.id}"
}


