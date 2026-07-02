variable "name" { type = string }
variable "ami_id" { type = string }
variable "instance_type" { type = string default = "t3.micro" }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "public_key" { type = string }
variable "instance_profile_name" { type = string }
variable "volume_size" { type = number default = 20 }

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = var.public_key
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true

  root_block_device { volume_size = var.volume_size volume_type = "gp3" }

  user_data = <<-EOF2
#!/bin/bash
set -eux
apt-get update
apt-get install -y docker.io docker-compose-plugin git nginx certbot python3-certbot-nginx awscli
systemctl enable --now docker nginx
usermod -aG docker ubuntu || true
EOF2

  tags = { Name = "${var.name}-web" }
}

output "public_ip" { value = aws_instance.web.public_ip }
output "public_dns" { value = aws_instance.web.public_dns }
