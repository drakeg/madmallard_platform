variable "aws_region" { type = string default = "us-east-1" }
variable "name" { type = string default = "madmallard-dev" }
variable "ssh_cidr" { type = string description = "Your IP CIDR for SSH, e.g. 1.2.3.4/32" }
variable "public_key" { type = string description = "SSH public key contents" }
variable "ami_id" { type = string description = "Ubuntu AMI ID for selected region" }
variable "instance_type" { type = string default = "t3.micro" }
