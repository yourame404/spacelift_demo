output "key_ssm_param" {
  value = aws_ssm_parameter.private_key.name
}

output "public_ip" {
  value = aws_instance.demo_instance.public_ip
}
