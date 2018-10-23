#####################################################################
##
##      Created 6/4/18 by ucdpadmin. for ibm
##
#####################################################################

output "url" {
  value = "http://${ibm_compute_vm_instance.vm_webserver.ipv4_address}:8080/JPetStore"
}
