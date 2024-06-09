output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.tnc_instance.public_ip
}

output "ssh_private_key" {
  description = "The private key for SSH access"
  value       = tls_private_key.tnc_key.private_key_pem
  sensitive   = true
}
