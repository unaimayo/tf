#####################################################################
##
##      Created 11/11/19 by ucdpadmin for cloud 304454_unai.mayo. for tomcat
##
#####################################################################

terraform {
  required_version = "~> 0.12"
}

provider "ibm" {
  version = "~> 1.20"
}

provider "ucd" {
  username       = var.ucd_user
  password       = var.ucd_password
  ucd_server_url = var.ucd_server_url
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "ibm_cloud_temp_public_key" {
  label = "ibm-cloud-temp-public-key"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "ibm_compute_vm_instance" "vm_webserver" {
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  disks                    = [25]
  domain      = var.vm_domain
  hostname    = var.vm_webserver_hostname
  datacenter  = var.vm_datacenter
  ssh_key_ids = [ibm_compute_ssh_key.ibm_cloud_temp_public_key.id]
  os_reference_code = var.vm_os_reference_code
  
  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = tls_private_key.ssh.private_key_pem
    host        = self.ipv4_address
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

Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
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
    agent_name      = var.vm_webserver_hostname
    ucd_server_url  = var.ucd_server_url
    ucd_user        = var.ucd_user
    ucd_password    = var.ucd_password
    type            = "web"
  }
  provisioner "local-exec" {
    when = destroy
    command = <<EOT
    curl -k -u ${var.ucd_user}:${var.ucd_password} ${var.ucd_server_url}/cli/agentCLI?agent=${var.vm_webserver_hostname} -X DELETE
EOT
}
}



