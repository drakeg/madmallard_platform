variable "name" {
  type = string
}

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

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "subnet_id" {
  type = string
}
variable "security_group_ids" {
  type = list(string)
}
variable "public_key" {
  type = string
}
variable "instance_profile_name" {
  type = string
}
variable "volume_size" {
  type    = number
  default = 20
}

variable "web_server" {
  type        = string
  default     = "caddy"
  description = "Reverse proxy to install/configure. Supported: caddy, nginx."

  validation {
    condition     = contains(["caddy", "nginx"], var.web_server)
    error_message = "web_server must be one of: caddy, nginx."
  }
}

variable "certificate_provider" {
  type        = string
  default     = "letsencrypt"
  description = "TLS certificate provider profile. Supported: letsencrypt, aws-acm-acme, none. letsencrypt is the cheapest bootstrap option."

  validation {
    condition     = contains(["letsencrypt", "aws-acm-acme", "none"], var.certificate_provider)
    error_message = "certificate_provider must be one of: letsencrypt, aws-acm-acme, none."
  }
}

variable "acme_email" {
  type        = string
  default     = ""
  description = "Email address used for ACME registration. Recommended for Let's Encrypt/Caddy."
}

variable "primary_domain" {
  type        = string
  default     = ""
  description = "Primary domain for the app. Leave blank until DNS points to this EC2 instance."
}

variable "additional_domains" {
  type        = list(string)
  default     = []
  description = "Additional domains served by this EC2 instance, one per tenant/business identity."
}

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

  caddy_sites = join("\n\n", [for d in compact(concat([var.primary_domain], var.additional_domains)) : <<-SITE
${d} {
    reverse_proxy 127.0.0.1:8000
}
SITE
  ])

  caddy_global_options = var.acme_email != "" ? join("\n", [
    "{",
    "    email ${var.acme_email}",
    "}",
  ]) : ""

  caddy_default_site = join("\n", [
    ":80 {",
    "    reverse_proxy 127.0.0.1:8000",
    "}",
  ])

  caddyfile = var.primary_domain != "" ? trimspace(join("\n\n", compact([local.caddy_global_options, local.caddy_sites]))) : local.caddy_default_site

  ubuntu_user_data = <<-EOF2
#!/bin/bash
set -eux
apt-get update
apt-get install -y ca-certificates curl gnupg git awscli
# Ensure stale packages from earlier bootstrap attempts do not keep serving the default page.
if systemctl list-unit-files | grep -q "^nginx.service"; then
  systemctl stop nginx || true
  systemctl disable nginx || true
fi
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
. /etc/os-release
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [ "${var.web_server}" = "caddy" ]; then
  apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
  apt-get update
  apt-get install -y caddy
  systemctl stop nginx || true
  systemctl disable nginx || true
  cat > /etc/caddy/Caddyfile <<'CADDYFILE'
${local.caddyfile}
CADDYFILE
  systemctl enable --now caddy
else
  apt-get install -y nginx certbot python3-certbot-nginx
  systemctl enable --now nginx
fi
systemctl enable --now docker
usermod -aG docker ubuntu || true
mkdir -p /opt/madmallard-platform
EOF2

  amazon_linux_2023_user_data = <<-EOF2
#!/bin/bash
set -eux
dnf update -y
dnf install -y docker git awscli
# Ensure stale packages from earlier bootstrap attempts do not keep serving the default page.
if systemctl list-unit-files | grep -q "^nginx.service"; then
  systemctl stop nginx || true
  systemctl disable nginx || true
fi
if [ "${var.web_server}" = "caddy" ]; then
  dnf install -y 'dnf-command(copr)'
  dnf copr enable -y @caddy/caddy
  dnf install -y caddy
  systemctl stop nginx || true
  systemctl disable nginx || true
  cat > /etc/caddy/Caddyfile <<'CADDYFILE'
${local.caddyfile}
CADDYFILE
  systemctl enable --now caddy
else
  dnf install -y nginx certbot python3-certbot-nginx
  systemctl enable --now nginx
fi
systemctl enable --now docker
usermod -aG docker ec2-user || true
mkdir -p /usr/libexec/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose
mkdir -p /opt/madmallard-platform
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

  # Recreate the instance when bootstrap/profile changes. This keeps Terraform
  # honest while the app is still a cheap single-node deployment.
  user_data_replace_on_change = true

  tags = {
    Name       = "${var.name}-web"
    AmiFamily           = var.ami_family
    WebServer           = var.web_server
    CertificateProvider = var.certificate_provider
    ManagedBy           = "terraform"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
output "public_dns" {
  value = aws_instance.web.public_dns
}
output "ami_id" {
  value = local.selected_ami_id
}
output "ami_family" {
  value = var.ami_family
}
output "ssh_user" {
  value = local.ssh_user
}

output "web_server" {
  value = var.web_server
}

output "certificate_provider" {
  value = var.certificate_provider
}

output "primary_domain" {
  value = var.primary_domain
}
