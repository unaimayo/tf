#####################################################################
##
##      Created 5/5/21 by ucdpadmin for cloud azure_mapfre. for azure
##
#####################################################################


output "url" {
  value = "http://${azurerm_linux_virtual_machine.webserver.public_ip_address}:8080/JPetStore"
}


