variable "name" { type = string }
variable "vpc_id" { type = string }
variable "ssh_cidr" { type = string }

resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "HTTP/HTTPS and restricted SSH"
  vpc_id      = var.vpc_id

  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = [var.ssh_cidr] }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }

  tags = { Name = "${var.name}-web-sg" }
}

output "web_sg_id" { value = aws_security_group.web.id }
