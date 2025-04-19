# Terraform + Ansible AWS Infrastructure

This project uses Terraform and Ansible to provision and configure AWS infrastructure through Spacelift.

## Features

- AWS VPC and subnet creation
- EC2 instance provisioning
- Dynamic inventory with AWS EC2 plugin
- Apache web server installation and configuration

## Prerequisites

- AWS Account and credentials
- Terraform ≥ 1.0
- Ansible
- Spacelift account

## Structure

```
.
├── README.md
├── ansible/
│   ├── ansible.cfg
│   ├── aws_ec2.yml
│   └── playbook.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── spacelift.yaml
```

## Usage

1. Set up AWS credentials
2. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
3. Run Ansible playbook:
   ```bash
   cd ../ansible
   ansible-playbook playbook.yml
   ```

## Infrastructure

- VPC with public subnet
- EC2 instance running Ubuntu
- Apache web server

## Configuration Management

The Ansible playbook:
- Updates system packages
- Installs and configures Apache
- Deploys a custom index page

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request