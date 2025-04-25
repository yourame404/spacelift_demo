terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

// Generate SSH key pair
resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Create AWS key pair
resource "aws_key_pair" "demo_keypairr" {
  key_name   = "demo-keypairr"
  public_key = tls_private_key.demo_key.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo '${tls_private_key.demo_key.private_key_pem}' > ~/.ssh/demo-key.pem
      chmod 400 ~/.ssh/demo-key.pem
    EOT
  }
}

resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "demo-vpc" }
}

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id
  tags = { Name = "demo-igw" }
}

resource "aws_route_table" "demo_rt" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = { Name = "demo-rt" }
}

resource "aws_subnet" "demo_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = { Name = "demo-subnet" }
}

resource "aws_route_table_association" "demo_rta" {
  subnet_id      = aws_subnet.demo_subnet.id
  route_table_id = aws_route_table.demo_rt.id
}

// Create security group for SSH access
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

    tags = { Name = "demo-sg" }
}

resource "aws_instance" "demo_instance" {
  ami           = "ami-03f65b8614a860c29"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.demo_subnet.id
  key_name      = aws_key_pair.demo_keypair.key_name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]
    user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip python3-venv
              EOF
  
  tags = { Name = "demo-instance" }
}

# Output the private key for reference
output "private_key" {
  value     = tls_private_key.demo_key.private_key_pem
  sensitive = true
}

# Output the public IP
output "public_ip" {
  value = aws_instance.demo_instance.public_ip
}