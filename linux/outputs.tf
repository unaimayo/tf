#####################################################################
##
##      Created 12/18/19 by admin. for linux
##
#####################################################################


output "vm_ip" {
  value = "${ibm_compute_vm_instance.ubuntu_small_virtual_guest.ipv4_address}"
}

output "ssh_private_key" {
  value = "${tls_private_key.ssh.private_key_pem}"
}