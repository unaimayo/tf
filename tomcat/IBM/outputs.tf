#####################################################################
##
##      Created 11/11/19 by ucdpadmin for cloud 304454_unai.mayo. for tomcat
##
#####################################################################

output "vm_ip" {
  value = "Public : ${ibm_compute_vm_instance.ubuntu_small_virtual_guest.ipv4_address}"
}

output "tomcat_url" {
  value = "http://${ibm_compute_vm_instance.ubuntu_small_virtual_guest.ipv4_address}:8080"
}