#####################################################################
##
##      Created 6/4/18 by ucdpadmin. for aws
##
#####################################################################

output "jpetstore" {
  value = "http://${aws_instance.webserver.public_ip}:8080/JPetStore"
}