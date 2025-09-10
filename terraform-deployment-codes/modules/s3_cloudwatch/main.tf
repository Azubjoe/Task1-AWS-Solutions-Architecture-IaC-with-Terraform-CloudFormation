resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name != "" ? var.bucket_name : "${var.project}-${var.env}-${random_id.suffix.hex}"
  acl    = "private"
  versioning { enabled = true }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "logs-lifecycle"
    enabled = true
    prefix  = "logs/"
    expiration { days = 365 }
  }

  tags = { Name = "${var.project}-${var.env}-bucket" }
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/${var.project}-${var.env}/app"
  retention_in_days = 14
}

output "s3_bucket_name" { value = aws_s3_bucket.app_bucket.bucket }
output "cloudwatch_log_group" { value = aws_cloudwatch_log_group.app_logs.name }
