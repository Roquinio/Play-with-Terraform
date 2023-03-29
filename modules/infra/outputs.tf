output "myip" {
  value       = aws_instance.ec2-5src4.public_ip
  description = "Adress IP publique de l'instance"
}