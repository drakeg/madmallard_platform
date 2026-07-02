variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "madmallard-dev"
}

variable "ssh_cidr" {
  type        = string
  description = "Your IP CIDR for SSH, e.g. 1.2.3.4/32"
}

variable "public_key" {
  type        = string
  description = "SSH public key contents"
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "Optional pinned AMI ID. Leave blank to use latest AMI lookup from ami_family."
}

variable "ami_family" {
  type        = string
  default     = "ubuntu-24.04"
  description = "AMI family to auto-discover when ami_id is blank. Supported: ubuntu-24.04, ubuntu-22.04, amazon-linux-2023."
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
