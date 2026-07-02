output "web_public_ip" { value = module.ec2.public_ip }
output "web_public_dns" { value = module.ec2.public_dns }
output "backup_bucket_name" { value = module.s3.backup_bucket_name }
