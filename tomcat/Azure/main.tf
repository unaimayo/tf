#####################################################################
##
##      Created 12/16/18 by ucdpadmin. for agbar
##
#####################################################################

terraform {
  required_version = "> 0.8.0"
}

#########################################################
# Define the Azure provider
#########################################################
provider "azurerm" {
  version = "~> 0.2.2"
}

#########################################################
# Deploy the network resources
#########################################################
resource "random_id" "default" {
  byte_length = "4"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.name_prefix}-${random_id.default.hex}-rg"
  location = "${var.azure_region}"
}

resource "azurerm_virtual_network" "default" {
  name                = "${var.name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.default.name}"
}

resource "azurerm_subnet" "web" {
  name                 = "${var.name_prefix}-subnet-web"
  resource_group_name  = "${azurerm_resource_group.default.name}"
  virtual_network_name = "${azurerm_virtual_network.default.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "web" {
  name                         = "${var.name_prefix}-web-pip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.default.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "web" {
  name                = "${var.name_prefix}-web-nsg"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.default.name}"

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

resource "azurerm_network_interface" "web" {
  name                      = "${var.name_prefix}-web-nic1"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.default.name}"
  network_security_group_id = "${azurerm_network_security_group.web.id}"

  ip_configuration {
    name                          = "${var.name_prefix}-web-nic1-ipc"
    subnet_id                     = "${azurerm_subnet.web.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.web.id}"
  }
}

#########################################################
# Deploy the storage resources
#########################################################
resource "azurerm_storage_account" "default" {
  name                = "${format("st%s",random_id.default.hex)}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  location            = "${var.azure_region}"
  account_type        = "Standard_LRS"
}

resource "azurerm_storage_container" "default" {
  name                  = "default-container"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  storage_account_name  = "${azurerm_storage_account.default.name}"
  container_access_type = "private"
}

#########################################################
# Deploy the virtual machine resource
#########################################################
resource "azurerm_virtual_machine" "web" {
  name                  = "${var.name_prefix}-web-vm"
  location              = "${var.azure_region}"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  network_interface_ids = ["${azurerm_network_interface.web.id}"]
  vm_size               = "Standard_A2"

  provisioner "file" {
    destination = "/tmp"
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
  connection {
    type = "ssh"
    user = "${var.web_connection_user}"
    password = "${var.web_connection_password}"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.name_prefix}-web-os-disk1"
    vhd_uri       = "${azurerm_storage_account.default.primary_blob_endpoint}${azurerm_storage_container.default.name}/${var.name_prefix}-web-os-disk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.name_prefix}-web"
    admin_username = "${var.admin_user}"
    admin_password = "${var.admin_user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}



