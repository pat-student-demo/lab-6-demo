variable "app_name" {}

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
    echo "Hello ${var.app_name}" > /var/www/html/index.html
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "${var.app_name} server"
  }
}

resource "aws_key_pair" "admin" {
    key_name = "admin-key-${var.app_name}"
    public_key = file("/home/ubuntu/.ssh/github_sdo_key2.pub")
}

resource "aws_security_group" "vm_inbound" {
  name = "vm_inbound_${var.app_name}"

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