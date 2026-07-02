output "public_ip" { value = module.ec2.public_ip }
output "public_dns" { value = module.ec2.public_dns }
output "ami_id" { value = module.ec2.ami_id }
output "ami_family" { value = module.ec2.ami_family }
output "ssh_user" { value = module.ec2.ssh_user }
output "backup_bucket_name" { value = module.s3.backup_bucket_name }

output "web_server" { value = module.ec2.web_server }
output "certificate_provider" { value = module.ec2.certificate_provider }
output "primary_domain" { value = module.ec2.primary_domain }
