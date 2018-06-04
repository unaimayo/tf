#####################################################################
##
##      Created 6/4/18 by ucdpadmin. for ibm
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

provider "ibm" {
  version = "~> 0.7"
}

provider "ucd" {
  username       = "${var.ucd_user}"
  password       = "${var.ucd_password}"
  ucd_server_url = "${var.ucd_server_url}"
}


resource "ibm_compute_vm_instance" "vm_dbserver" {
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  disks                    = [25]
  domain      = "${var.vm_domain}"
  hostname    = "${var.vm_dbserver_hostname}"
  datacenter  = "${var.vm_datacenter}"
  ssh_key_ids = ["${ibm_compute_ssh_key.ibm_cloud_temp_public_key.id}"]
  os_reference_code = "${var.vm_os_reference_code}"
  
  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  
  provisioner "file" {
    destination = "/tmp/install_mariadb.sh"
    content     = <<EOT
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

cat << EOF > createdb.sql
create database jpetstore;
create user 'jpetstore'@'localhost' identified by 'jppwd';
grant all privileges on jpetstore.* to 'jpetstore'@'%' identified by 'jppwd';
EOF
mysql -p$PASSWORD < createdb.sql
EOT
  }

  provisioner "remote-exec" {
     inline = [
        "chmod +x /tmp/install_mariadb.sh",
        "sudo bash /tmp/install_mariadb.sh ${var.mariadb_password}"
      ]
  }
  
  provisioner "ucd" {
    agent_name      = "${var.vm_dbserver_hostname}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
}

resource "ibm_compute_vm_instance" "vm_webserver" {
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  disks                    = [25]
  domain      = "${var.vm_domain}"
  hostname    = "${var.vm_webserver_hostname}"
  datacenter  = "${var.vm_datacenter}"
  ssh_key_ids = ["${ibm_compute_ssh_key.ibm_cloud_temp_public_key.id}"]
  os_reference_code = "${var.vm_os_reference_code}"
  
  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }
  
  provisioner "file" {
    destination = "/tmp/install_tomcat.sh"
    content     = <<EOT
#!/bin/bash
LOGFILE="/var/log/install_tomcat.log"
TOMCAT_USER=tomcat
TOMCAT_GROUP=tomcat
TOMCAT_PATH=$1
TOMCAT_VERSION=$2
TOMCAT_ADMIN_USER=$3
TOMCAT_ADMIN_PWD=$4

apt-get update
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
cat << EOF > $TOMCAT_PATH/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
  <role rolename="manager-script"/>
  <user username="$TOMCAT_ADMIN_USER" password="$TOMCAT_ADMIN_PWD" roles="manager-script"/>
</tomcat-users>
EOF
# change owner
chown -R $TOMCAT_USER:$TOMCAT_GROUP $TOMCAT_PATH || fail "Error changing owner for $TOMCAT_PATH"
# clean up
rm -f $TOMCAT_SOFT
# create systemd service
cat << EOF > /etc/systemd/system/tomcat.service
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
EOF
# Add JPetSTore images folder
mkdir -p /opt/jpetstore/images
cd $TOMCAT_PATH/conf
awk '/<\/Host>/ { print "        <Context docBase=\"/opt/jpetstore/images\" path=\"/images\" />"; print; next }1' server.xml > server.xml.1
mv server.xml.1 server.xml
# start & enable tomcat service
systemctl enable tomcat || fail "Error enabling tomcat service"
systemctl start tomcat || fail "Error starting tomcat service"
EOT
  }
  
  provisioner "remote-exec" {
     inline = [
        "chmod +x /tmp/install_tomcat.sh",
        "sudo bash /tmp/install_tomcat.sh ${var.tomcat_home} ${var.tomcat_version} ${var.tomcat_admin_user} ${var.tomcat_admin_password}"
      ]
  }
  
  provisioner "ucd" {
    agent_name      = "${var.vm_webserver_hostname}"
    ucd_server_url  = "${var.ucd_server_url}"
    ucd_user        = "${var.ucd_user}"
    ucd_password    = "${var.ucd_password}"
  }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "ibm_cloud_temp_public_key" {
  label = "ibm-cloud-temp-public-key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

resource "ucd_component_mapping" "JPetStore_DB" {
  component = "JPetStore-DB"
  description = "JPetStore-DB Component"
  parent_id = "${ucd_agent_mapping.vm_dbserver_agent.id}"
}

resource "ucd_component_mapping" "JPetStore_APP" {
  component = "JPetStore-APP"
  description = "JPetStore-APP Component"
  parent_id = "${ucd_agent_mapping.vm_webserver_agent.id}"
}

resource "ucd_component_mapping" "JPetStore_WEB" {
  component = "JPetStore-WEB"
  description = "JPetStore-WEB Component"
  parent_id = "${ucd_agent_mapping.vm_webserver_agent.id}"
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
      name = "db.user"
      value = "jpetstore"
      secure = false
  }
  component_property {
      component = "JPetStore-DB"
      name = "db.password"
      value = "jppwd"
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
      name = "tomcat.start"
      value = "${var.tomcat_home}/bin/startup.sh"  # Generated
      secure = false
  }
  component_property {
      component = "JPetStore-APP"
      name = "db.url"
      value = "jdbc:mysql://${ibm_compute_vm_instance.vm_dbserver.ipv4_address}:3306/jpetstore"
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
      value = "http://localhost:8080"
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
      value = "8080"
      secure = false
  }
  component_property {
      component = "JPetStore-WEB"
      name = "images.path"
      value = "/opt/jpetstore/images"
      secure = false
  }
}

resource "ucd_agent_mapping" "vm_dbserver_agent" {
  description = "Agent to manage the vm_dbserver server"
  agent_name = "${var.vm_dbserver_hostname}.${ibm_compute_vm_instance.vm_dbserver.ipv4_address_private}"
  parent_id = "${ucd_resource_tree.resource_tree.id}"
}

resource "ucd_agent_mapping" "vm_webserver_agent" {
  description = "Agent to manage the vm_webserver server"
  agent_name = "${var.vm_webserver_hostname}.${ibm_compute_vm_instance.vm_webserver.ipv4_address_private}"
  parent_id = "${ucd_resource_tree.resource_tree.id}"
}

resource "ucd_application_process_request" "application_process_request" {
  depends_on = [ "ucd_component_mapping.JPetStore_DB", "ucd_component_mapping.JPetStore_APP", "ucd_component_mapping.JPetStore_WEB" ]
  application = "JPetStore"
  application_process = "Deploy JPetStore"
  snapshot = "${var.snapshot}"
  environment = "${ucd_environment.environment.name}"
}