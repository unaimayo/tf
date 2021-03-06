#####################################################################
##
##      Created 6/4/18 by ucdpadmin. for aws
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

provider "aws" {
}

provider "ucd" {
  username       = "${var.ucd_user}"
  password       = "${var.ucd_password}"
  ucd_server_url = "${var.ucd_server_url}"
}


data "aws_vpc" "selected_vpc" {
  filter {
    name = "tag:Name"
    values = ["${var.aws_vpc_name}"]
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "internal_key" {
  key_name   = "${var.key_pair_name}"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

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
apt-get update
apt-get install -y mariadb-server
systemctl stop mysql
sed -i "s/bind-address.*/bind-address = ::/" /etc/mysql/mariadb.conf.d/50-server.cnf
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
    agent_name      = "${var.environment_name}"
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

##> Web Server
resource "aws_instance" "webserver" {
  ami = "${var.ami}"
  key_name = "${aws_key_pair.internal_key.id}"
  instance_type = "${var.aws_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.webserver.id}"]
  connection {
    user = "ubuntu"
    private_key = "${tls_private_key.ssh.private_key_pem}"
  }
  
  provisioner "file" {
    content = <<EOF
#!/bin/bash
LOGFILE="/var/log/install_tomcat.log"
TOMCAT_USER=tomcat
TOMCAT_GROUP=tomcat
TOMCAT_PATH=$1
TOMCAT_VERSION=$2
TOMCAT_ADMIN_USER=$3
TOMCAT_ADMIN_PWD=$4

apt-get install -y wget
# create user and group
groupadd $TOMCAT_GROUP
useradd -M -s /bin/nologin -g $TOMCAT_GROUP -d $TOMCAT_PATH $TOMCAT_USER
mkdir -p $TOMCAT_PATH
# download software
TOMCAT_SOFT="apache-tomcat-$TOMCAT_VERSION.tar.gz"
wget http://apache.rediris.es/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/$TOMCAT_SOFT
# install jdk
apt-get install -y openjdk-8-jdk
# install tomcat
tar xfz $TOMCAT_SOFT -C $TOMCAT_PATH --strip-components=1
# create admin user
cat << EOT > $TOMCAT_PATH/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
  <role rolename="manager-script"/>
  <user username="$TOMCAT_ADMIN_USER" password="$TOMCAT_ADMIN_PWD" roles="manager-script"/>
</tomcat-users>
EOT
# change owner
chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_PATH || fail "Error changing owner for $TOMCAT_PATH"
# clean up
rm -f $TOMCAT_SOFT
# create systemd service
cat << EOT > /etc/systemd/system/tomcat.service
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_PID=$TOMCAT_PATH/temp/tomcat.pid
Environment=CATALINA_HOME=$TOMCAT_PATH
Environment=CATALINA_BASE=$TOMCAT_PATH
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=$TOMCAT_PATH/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID

User=$TOMCAT_USER
Group=$TOMCAT_GROUP
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOT
# Add JPetSTore images folder
mkdir -p /opt/jpetstore/images
cd $TOMCAT_PATH/conf
awk '/<\/Host>/ { print "        <Context docBase=\"/opt/jpetstore/images\" path=\"/images\" />"; print; next }1' server.xml > server.xml.1
mv server.xml.1 server.xml
# start & enable tomcat service
systemctl enable tomcat || fail "Error enabling tomcat service"
systemctl start tomcat || fail "Error starting tomcat service"

EOF

    destination = "/tmp/install_tomcat.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_tomcat.sh; sudo bash /tmp/install_tomcat.sh \"${var.tomcat_home}\" \"${var.tomcat_version}\" \"${var.tomcat_admin_user}\" \"${var.tomcat_admin_password}\"",
    ]
  }
  
  provisioner "ucd" {
    agent_name      = "${var.environment_name}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
  tags {
    Name = "${var.webserver_name}"
  }
}

resource "aws_security_group" "webserver" {
  name = "webserver"
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
    from_port = 8080
    to_port = 8080
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
    Name = "webserver"
  }
}

##> UCD
resource "ucd_component_mapping" "JPetStore_DB" {
  component = "JPetStore-DB"
  description = "JPetStore-DB Component"
  parent_id = "${ucd_agent_mapping.dbserver_agent.id}"
}

resource "ucd_component_mapping" "JPetStore_WEB" {
  component = "JPetStore-WEB"
  description = "JPetStore-WEB Component"
  parent_id = "${ucd_agent_mapping.webserver_agent.id}"
}

resource "ucd_component_mapping" "JPetStore_APP" {
  component = "JPetStore-APP"
  description = "JPetStore-APP Component"
  parent_id = "${ucd_agent_mapping.webserver_agent.id}"
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
      value = "${var.mariadb_password}"
      secure = false
  }
  component_property {
      component = "JPetStore-DB"
      name = "db.user"
      value = "jpetstore"
      secure = false
  }
  
  component_property {
      component = "JPetStore-WEB"
      name = "images.path"
      value = "/opt/jpetstore/images"
      secure = false
  }
  
  component_property {
      component = "JPetStore-APP"
      name = "tomcat.start"
      value = "${var.tomcat_home}/bin/startup.sh"
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "tomcat.password"
      value = "${var.tomcat_admin_password}"
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "db.url"
      value = "jdbc:mysql://${aws_instance.dbserver.private_ip}:3306/jpetstore"
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "tomcat.user"
      value = "${var.tomcat_admin_user}"
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "tomcat.url"
      value = "http://localhost:${var.tomcat_port}"
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "tomcat.home"
      value = "${var.tomcat_home}"
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "tomcat.port"
      value = "${var.tomcat_port}"
      secure = false
  }  
}

resource "ucd_agent_mapping" "dbserver_agent" {
  description = "Agent to manage the dbserver server"
  agent_name = "${var.environment_name}.${aws_instance.dbserver.private_ip}"
  parent_id = "${ucd_resource_tree.resource_tree.id}"
}

resource "ucd_agent_mapping" "webserver_agent" {
  description = "Agent to manage the webserver server"
  agent_name = "${var.environment_name}.${aws_instance.webserver.private_ip}"
  parent_id = "${ucd_resource_tree.resource_tree.id}"
}

resource "ucd_application_process_request" "application_process_request" {
  depends_on = [ "ucd_component_mapping.JPetStore_DB", "ucd_component_mapping.JPetStore_WEB", "ucd_component_mapping.JPetStore_APP" ]
  application = "JPetStore"
  application_process = "Deploy JPetStore"
  snapshot = "1.0"
  environment = "${ucd_environment.environment.name}"
}

