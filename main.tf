terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.admin.key_name
  security_groups = [aws_security_group.vm_inbound.name]

  user_data = <<-EOF
    #!/bin/bash
    echo Installing nginx
    sudo apt-get update -y
    sudo apt-get install nginx -y
    sudo chown :ubuntu /var/www/html
    sudo chmod g+w /var/www/html
    echo "Hello foo" > /var/www/html/index.html
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "foo server"
  }
}

resource "aws_key_pair" "admin" {
    key_name = "admin-key"
    public_key = file("/home/ubuntu/.ssh/github_sdo_key2.pub")
}

resource "aws_security_group" "vm_inbound" {
  name = "vm_inbound"

  # SSH
  ingress {
    from_port = 0
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP in
  ingress {
    from_port = 0
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS out
  egress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vm_public_hostname" {
  value = aws_instance.app.public_dns
}

