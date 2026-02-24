# Sensitive parameters - values come from Terraform variables
resource "aws_ssm_parameter" "secret_key" {
  name  = "/cloudtalents/startup/secret_key"
  type  = "SecureString"
  value = var.secret_key

  tags = {
    Project = var.project_name
  }
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/cloudtalents/startup/db_user"
  type  = "SecureString"
  value = var.db_username

  tags = {
    Project = var.project_name
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/cloudtalents/startup/db_password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Project = var.project_name
  }
}

# Dynamic parameters - values come from existing Terraform resources
resource "aws_ssm_parameter" "database_endpoint" {
  name  = "/cloudtalents/startup/database_endpoint"
  type  = "String"
  value = aws_db_instance.postgres.endpoint

  tags = {
    Project = var.project_name
  }
}

resource "aws_ssm_parameter" "image_storage_bucket_name" {
  name  = "/cloudtalents/startup/image_storage_bucket_name"
  type  = "String"
  value = aws_s3_bucket.media.id

  tags = {
    Project = var.project_name
  }
}

resource "aws_ssm_parameter" "image_storage_cloudfront_domain" {
  name  = "/cloudtalents/startup/image_storage_cloudfront_domain"
  type  = "String"
  value = aws_cloudfront_distribution.media.domain_name

  tags = {
    Project = var.project_name
  }
}