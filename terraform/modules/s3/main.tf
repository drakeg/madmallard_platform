variable "name" {
  type = string
}

resource "aws_s3_bucket" "backups" {
  bucket_prefix = "${var.name}-backups-"

  tags = {
    Name = "${var.name}-backups"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backups.bucket
}
