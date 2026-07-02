variable "name" { type = string }

variable "ami_id" {
  type        = string
  default     = ""
  description = "Optional pinned AMI ID. When set, this overrides ami_family lookup."
}

variable "ami_family" {
  type        = string
  default     = "ubuntu-24.04"
  description = "AMI family to discover when ami_id is empty. Supported: ubuntu-24.04, ubuntu-22.04, amazon-linux-2023."

  validation {
    condition     = contains(["ubuntu-24.04", "ubuntu-22.04", "amazon-linux-2023"], var.ami_family)
    error_message = "ami_family must be one of: ubuntu-24.04, ubuntu-22.04, amazon-linux-2023."
  }
}

variable "instance_type" { type = string default = "t3.micro" }
variable "subnet_id" { type = string }
variable "security_group_ids" { type = list(string) }
variable "public_key" { type = string }
variable "instance_profile_name" { type = string }
variable "volume_size" { type = number default = 20 }

data "aws_ami" "ubuntu_2404" {
  count       = var.ami_id == "" && var.ami_family == "ubuntu-24.04" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu_2204" {
  count       = var.ami_id == "" && var.ami_family == "ubuntu-22.04" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == "" && var.ami_family == "amazon-linux-2023" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  discovered_ami_id = var.ami_family == "ubuntu-24.04" ? try(data.aws_ami.ubuntu_2404[0].id, null) : var.ami_family == "ubuntu-22.04" ? try(data.aws_ami.ubuntu_2204[0].id, null) : try(data.aws_ami.amazon_linux_2023[0].id, null)
  selected_ami_id   = var.ami_id != "" ? var.ami_id : local.discovered_ami_id
  ssh_user          = var.ami_family == "amazon-linux-2023" ? "ec2-user" : "ubuntu"

  ubuntu_user_data = <<-EOF2
#!/bin/bash
set -eux
apt-get update
apt-get install -y docker.io docker-compose-plugin git nginx certbot python3-certbot-nginx awscli
systemctl enable --now docker nginx
usermod -aG docker ubuntu || true
EOF2

  amazon_linux_2023_user_data = <<-EOF2
#!/bin/bash
set -eux
dnf update -y
dnf install -y docker git nginx certbot python3-certbot-nginx awscli
systemctl enable --now docker nginx
usermod -aG docker ec2-user || true
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose
EOF2

  user_data = var.ami_family == "amazon-linux-2023" ? local.amazon_linux_2023_user_data : local.ubuntu_user_data
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = var.public_key
}

resource "aws_instance" "web" {
  ami                         = local.selected_ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  user_data = local.user_data

  tags = {
    Name       = "${var.name}-web"
    AmiFamily  = var.ami_family
    ManagedBy  = "terraform"
  }
}

output "public_ip" { value = aws_instance.web.public_ip }
output "public_dns" { value = aws_instance.web.public_dns }
output "ami_id" { value = local.selected_ami_id }
output "ami_family" { value = var.ami_family }
output "ssh_user" { value = local.ssh_user }
