# s3.tf

resource "aws_s3_bucket" "media" {
  bucket = "cloudwithben-media-dev"

  tags = {
    Name        = "cloudwithben-media-dev"
    Environment = "dev"
  }
}

# Block all public access — CloudFront will be the only entry point
resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}