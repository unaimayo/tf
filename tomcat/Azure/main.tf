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

#################################
# Execute Ansible playbook
#################################

resource "null_resource" "execute_ansible" {
  depends_on = ["azurerm_virtual_machine.web"]

  # Specify the ssh connection
  connection {
    type        = "ssh"
    user        = "${var.ansible_user}"
    password    = "${var.ansible_password}"
    host        = "${var.ansible_host}"
  }

  # Create the Host File for example
  provisioner "file" {
    content = <<EOF
default ansible_host=${azurerm_public_ip.web.ip_address} ansible_user='${var.admin_user}' ansible_password='${var.admin_user_password}' ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

    destination = "/tmp/ansible-playbook-host"
  }

  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "cd agbar && ansible-playbook -i \"/tmp/ansible-playbook-host\" configure-linux-box.yml",
    ]
  }
}

