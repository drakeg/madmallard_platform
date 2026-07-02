module "networking" {
  source = "../../modules/networking"
  name   = var.name
}

module "security" {
  source   = "../../modules/security"
  name     = var.name
  vpc_id   = module.networking.vpc_id
  ssh_cidr = var.ssh_cidr
}

module "s3" {
  source = "../../modules/s3"
  name   = var.name
}

module "iam" {
  source            = "../../modules/iam"
  name              = var.name
  backup_bucket_arn = "arn:aws:s3:::${module.s3.backup_bucket_name}"
}

module "ec2" {
  source                = "../../modules/ec2"
  name                  = var.name
  ami_id                = var.ami_id
  ami_family            = var.ami_family
  instance_type         = var.instance_type
  subnet_id             = module.networking.public_subnet_id
  security_group_ids    = [module.security.web_sg_id]
  public_key            = var.public_key
  instance_profile_name = module.iam.instance_profile_name
  web_server            = var.web_server
  certificate_provider  = var.certificate_provider
  acme_email            = var.acme_email
  primary_domain        = var.primary_domain
  additional_domains    = var.additional_domains
}
