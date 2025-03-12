provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "notification_email" {
  description = "Email address to receive security notifications"
  type        = string
  default     = "security-alerts@example.com"
}

variable "enable_guardduty" {
  description = "Enable GuardDuty for threat detection"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Enable Security Hub for security findings aggregation"
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "Number of days to retain CloudWatch Logs"
  type        = number
  default     = 90
}

# SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name         = "security-alerts-topic"
  display_name = "Security Alerts"
}

# SNS Subscription for Email Notifications
resource "aws_sns_topic_subscription" "security_alerts_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket_prefix = "security-cloudtrail-logs-"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/security-monitoring"
  retention_in_days = var.log_retention_in_days
}

# IAM Role for CloudTrail to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_logs" {
  name = "cloudtrail-to-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs" {
  name = "cloudtrail-logs-policy"
  role = aws_iam_role.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# CloudTrail Configuration
resource "aws_cloudtrail" "security_trail" {
  name                          = "security-monitoring-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_logs.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs
  ]
}

# GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# Security Hub
resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0
}

# EventBridge Rule for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  count = var.enable_guardduty ? 1 : 0

  name        = "guardduty-findings-rule"
  description = "Rule for GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_findings_sns" {
  count = var.enable_guardduty ? 1 : 0

  rule      = aws_cloudwatch_event_rule.guardduty_findings[0].name
  target_id = "SecurityAlertsTopic"
  arn       = aws_sns_topic.security_alerts.arn
}

# EventBridge Rule for Security Hub Findings
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  count = var.enable_security_hub ? 1 : 0

  name        = "securityhub-findings-rule"
  description = "Rule for Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
  })
}

resource "aws_cloudwatch_event_target" "securityhub_findings_sns" {
  count = var.enable_security_hub ? 1 : 0

  rule      = aws_cloudwatch_event_rule.securityhub_findings[0].name
  target_id = "SecurityAlertsTopic"
  arn       = aws_sns_topic.security_alerts.arn
}

# CloudWatch Dashboard for Security Monitoring
resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "SecurityMonitoringDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudTrail", "CloudTrailEventCount", "EventName", "ConsoleLogin"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Console Login Events"
          period  = 300
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudTrail", "CloudTrailEventCount", "EventName", "CreateAccessKey"],
            ["AWS/CloudTrail", "CloudTrailEventCount", "EventName", "DeleteAccessKey"],
            ["AWS/CloudTrail", "CloudTrailEventCount", "EventName", "UpdateAccessKey"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "IAM Access Key Events"
          period  = 300
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudTrail", "CloudTrailEventCount", "EventSource", "iam.amazonaws.com"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "IAM API Calls"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarm for Unusual IAM Activity
resource "aws_cloudwatch_metric_alarm" "unusual_iam_activity" {
  alarm_name          = "UnusualIAMActivityAlarm"
  alarm_description   = "Alarm for unusual IAM activity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CloudTrailEventCount"
  namespace           = "AWS/CloudTrail"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.security_alerts.arn]

  dimensions = {
    EventSource = "iam.amazonaws.com"
  }
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# Outputs
output "security_alerts_topic_arn" {
  description = "ARN of the SNS topic for security alerts"
  value       = aws_sns_topic.security_alerts.arn
}

output "cloudtrail_logs_bucket" {
  description = "Name of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudtrail_log_group" {
  description = "Name of the CloudWatch Logs group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "security_dashboard_url" {
  description = "URL to the Security Monitoring Dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
} 