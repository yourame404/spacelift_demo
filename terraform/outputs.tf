output "private_key" {
  value     = tls_private_key.demo_key.private_key_pem
 sensitive = true
}

output "public_ip" {
  value = aws_instance.demo_instance.public_ip
}
