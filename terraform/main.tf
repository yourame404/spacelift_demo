terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
  access_key="ASIAUZW24WSVHQPIEV23"  
  secret_key="lvNP+r3Buy0XO+iRPox4aQMlRCTumiTDphaeo0ou"
  token="IQoJb3JpZ2luX2VjEG0aCXVzLXdlc3QtMiJIMEYCIQCuydZTi6HJr2SybV1P7C7zCFpNYdXi9C2a8nirVSWXJwIhAIP9ibUJMWI7ARs0ViLogngKXf2srScXLGoLAc1bAOXkKqQCCEYQABoMMzMwMDk3ODAwMzYyIgxxx3Bv9kHa4o1YkmIqgQK0C7l/dnavkwQPZgprMP6oCKvP+J3tRYvzfz6/XzFYZfXXyOpophp2LaGe6gb+0prH+kGDzQDYhKE+KLkvrQUU0apTJ2YZZM+FOK6JmkQWFaoxnXaVzekxWSAU9dW0E1PMnXCXWzaPjij/WRPTQSpHjxz2cOPDbdpGdB7ckQqV3sP99cAlD2jAwlQuz5X4KAz/LI6pTnUeL/1KqfDBe8D6fYVlvK3ellXI7OguyDXT2Xk/JotyADQk9L5hejZn5Uysr5SL8PtCZGCUw7UjrxVAF7Pc00UkFm0Dq6g0a2LDI4yOhzOcC4OxZrCUqmq7ASMKR9Fpo32//XJviOCNv9mXtDCJm4bCBjqcAZ6EKulKyb1tW6C0RCdL/To1n7+hfL7xCUPmwjPXyUaVzNURx85mhxNr/XqJtQj5jFzmyvP5ngwsLlnvN2rBbE/f5IpGRPEc2pAiQrqKNKg8ghf4GiK14QJEEP+wRRlLj8KCLejuL/g0aH8SnnthYWZzHopZ0qeaCzPx651hvPL5cXrx2mtva0wrB+lUmEViigFzS85Jwzv+teMh/g=="
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
