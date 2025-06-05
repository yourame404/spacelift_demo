terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
  access_key="ASIAUZW24WSVM5JBRTH7"  
  secret_key="3oIza/3X8DE1KD/DewFURDtQfh5Qzqm0cVGMZ/EO"
  token="IQoJb3JpZ2luX2VjEG4aCXVzLXdlc3QtMiJHMEUCIQCPY9v1j4G3Gi4Rnqm4fiJhova4RjjFcltV9csn+MErkAIgeem9dlKTt2TeO0CmlJgyrBdCPr9EKOt2/vrUuavzGVIqpAIIRxAAGgwzMzAwOTc4MDAzNjIiDJQiNYwEz2OT6Ctu5yqBAhrlCgn9JwfmKXeGurvd00lugyyB5ki7DW4jhI2GrwjEEthZ6JnJwvOl8h9lQKmnzOP3vRp+uSBXy5Uv6KaijU7xKesDJl+cwamlqUhJkrlkcg3VGaFR+R+Jh4ZewGi7o4YDJFWvvLIWAdvG8WZ3i4AFznvQlPIoz1m7fEfJ8IDP9Mo8rWDSNjza9BZ1a1oPXbO1n4MoLqZzO7cAw6RMBlgvBWds2UBEpEolne7lnozJoR4bGK76oUACxuicsdkrcPTdoeGL0ZyOE6C45U5fs9R6h6YKtH0g6TJQmm4uDJC81oNhE1CTg7994xa9dwFPjB07eB1YD9t3BqATn7OSkckhMIPNhsIGOp0BmGRtJYjLVcz396JHHcoMyt88PcNYBMLJYFg0JsWouUP6ihp+2ILRETs8VwJWtac4oFgLkA1ZyfIuYlhyqjXqUoCAxn8AdFN/7BDGh7e1Hrqmixo1i5EZszjSI65Sf8NUNz8crSptzfIvDGEf1x5QdapUMByLZ2DM6ofO+1/gMFCGVrtUjYxfZ1kwBcXqVM2uB1stgIGxMQI7jvV+mA=="
}

# Generate SSH key pair
resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Store private key in SSM Parameter Store
resource "aws_ssm_parameter" "private_key" {
  name        = "/ssh/demo-keypair/private"
  description = "Private SSH key for EC2 demo"
  type        = "SecureString"
  value       = tls_private_key.demo_key.private_key_pem

  tags = {
    environment = "demo"
  }
}

# Create AWS key pair using the public key
resource "aws_key_pair" "demo_keypair" {
  key_name   = "demo-keypair"
  public_key = tls_private_key.demo_key.public_key_openssh
}

# Create VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "demo-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "demo-igw"
  }
}

# Route Table
resource "aws_route_table" "demo_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = {
    Name = "demo-rt"
  }
}

# Subnet
resource "aws_subnet" "demo_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet"
  }
}

# Route Table Association
resource "aws_route_table_association" "demo_rta" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt.id
}

# Security Group
resource "aws_security_group" "demo_sg" {
  name        = "demo-sg"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}

# EC2 Instance
resource "aws_instance" "demo_instance" {
  ami                    = "ami-0779caf41f9ba54f0" // Replace with a valid AMI ID for your region
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.demo_subnet.id
  key_name               = aws_key_pair.demo_keypair.key_name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip python3-venv
  EOF

  tags = {
    Name = "demo-instance"
  }
}

# Outputs
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.demo_instance.public_ip
}
