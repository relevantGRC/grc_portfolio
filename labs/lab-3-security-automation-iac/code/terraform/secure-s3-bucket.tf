provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
  default     = "grc-lab-secure-bucket"
}

variable "environment" {
  description = "Environment tag (e.g., dev, test, prod)"
  type        = string
  default     = "lab"
}

# KMS key for S3 bucket encryption
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "s3-bucket-kms-key"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-bucket-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# S3 bucket with strong security controls
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Enable object lock configuration
resource "aws_s3_bucket_object_lock_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 7
    }
  }
}

# Lifecycle rule to expire old versions after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Configure logging to another bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.bucket_name}-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.bucket_name}-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Block all public access for log bucket
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption for log bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Add logging configuration to the main bucket
resource "aws_s3_bucket_logging" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "s3-access-logs/"
}

# Secure bucket policy
resource "aws_s3_bucket_policy" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Output bucket details
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.secure_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.secure_bucket.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption"
  value       = aws_kms_key.s3_key.arn
} 