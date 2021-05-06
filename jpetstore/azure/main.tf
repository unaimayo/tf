#####################################################################
##
##      Created 5/5/21 by ucdpadmin for cloud azure_mapfre. for azure
##
#####################################################################

terraform {
  required_version = "~> 0.12"
}

provider "azurerm" {
  features {}
  version = "~> 2.43"
}

provider "ucd" {
  username       = var.ucd_user
  password       = var.ucd_password
  ucd_server_url = var.ucd_server_url
}


resource "azurerm_virtual_network" "jpetstore_network" {
  name                = "jpetstore_network"
  address_space       = [var.azurerm_network_address_space]
  location            = var.vm_location
  resource_group_name   = azurerm_resource_group.jpetstore_group.name
}

resource "azurerm_network_interface" "interface" {
  name                = "jpetstore_network_interface"
  location            = var.vm_location
  resource_group_name = azurerm_resource_group.jpetstore_group.name
  ip_configuration {
    name                          = "ipConfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id  = azurerm_subnet.jpetstore_subnet.id
    public_ip_address_id = azurerm_public_ip.jpetstore_webserver_public_ip.id
  }
}

resource "azurerm_subnet" "jpetstore_subnet" {
  name                 = "jpetstore_subnet"
  virtual_network_name = azurerm_virtual_network.jpetstore_network.name
  address_prefixes     = [var.address_prefix]
  resource_group_name  = azurerm_resource_group.jpetstore_group.name
}

resource "azurerm_public_ip" "jpetstore_webserver_public_ip" {
  name                         = "jpetstore_webserver_public_ip"
  location                     = var.vm_location
  allocation_method = "Dynamic"
  resource_group_name   = azurerm_resource_group.jpetstore_group.name
  tags = {
    environment = "Production"
  }
}

resource "azurerm_resource_group" "jpetstore_group" {
  name = var.resource_group_name
  location = var.vm_location
}

resource "azurerm_linux_virtual_machine" "webserver" {
  name                = var.webserver_name
  location            = var.vm_location
  resource_group_name = azurerm_resource_group.jpetstore_group.name
  size                = "Standard_A1"
  admin_username      = var.webserver_azure_user
  admin_password      = var.webserver_azure_user_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.interface.id]
  
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
    agent_name      = var.webserver_name
    ucd_server_url  = var.ucd_server_url
    ucd_user        = var.ucd_user
    ucd_password    = var.ucd_password
    type            = "web"
  }
  provisioner "local-exec" {
    when = "destroy"
    command = <<EOT
    curl -k -u ${var.ucd_user}:${var.ucd_password} ${var.ucd_server_url}/cli/agentCLI?agent=${var.webserver_name} -X DELETE
EOT
}

  connection {
    host = self.public_ip_address
    user = self.admin_username
    password = self.admin_password
  }
  tags = {
    Name = var.webserver_name
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_disk {
    name                 = "${var.webserver_name}_os_disk_name"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_network_security_group" "jpetstore_security_group" {
  name                = "jpetstore_security_group"
  location            = var.vm_location
  resource_group_name   = azurerm_resource_group.jpetstore_group.name

  security_rule {
    name                       = "ssh-allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "custom-tcp-allow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "webserver_jpetstore_security_group_association" {
  network_interface_id      = azurerm_linux_virtual_machine.webserver.network_interface_ids[0]
  network_security_group_id = azurerm_network_security_group.jpetstore_security_group.id
}

resource "ucd_component_mapping" "JPetStore_APP_ORA_webserver" {
  component = "JPetStore-APP-ORA"
  description = "JPetStore-APP-ORA Component"
  parent_id = ucd_agent_mapping.webserver_agent.id
}

resource "ucd_component_mapping" "JPetStore_WEB_webserver" {
  component = "JPetStore-WEB"
  description = "JPetStore-WEB Component"
  parent_id = ucd_agent_mapping.webserver_agent.id
}
resource "ucd_resource_tree" "resource_tree" {
  base_resource_group_name = "Azure"
  parent = "MAPFRE/${var.ucd_environment}"
}



resource "ucd_agent_mapping" "webserver_agent" {
  depends_on = [ "azurerm_linux_virtual_machine.webserver" ]
  description = "Agent to manage the webserver server"
  agent_name = var.webserver_name
  parent_id = ucd_resource_tree.resource_tree.id
  timeout = "600"
}