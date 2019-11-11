#####################################################################
##
##      Created 12/16/18 by ucdpadmin. for agbar
##
#####################################################################

#########################################################
# Output
#########################################################
output "Tomcat VM Public IP" {
  value = "${azurerm_public_ip.web.ip_address}"
}

output "Tomcat Private IP" {
  value = "${azurerm_network_interface.web.private_ip_address}"
}

output "Please Verify Tomcat Installation" {
  value = "http://${azurerm_public_ip.web.ip_address}:8080"
}