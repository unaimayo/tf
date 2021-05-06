#####################################################################
##
##      Created 11/11/19 by ucdpadmin for cloud 304454_unai.mayo. for tomcat
##
#####################################################################

output "IP" {
  value = "${ibm_compute_vm_instance.vm_webserver.ipv4_address}"
}

output "url" {
  value = "http://${ibm_compute_vm_instance.vm_webserver.ipv4_address}:8080"
}