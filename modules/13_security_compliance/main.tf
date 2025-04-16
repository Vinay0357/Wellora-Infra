# -----------------------------------------------------------------------------
# Security & Compliance Module - Main Configuration
# Enables GuardDuty, Config, CloudTrail, Security Hub, Inspector v2, Macie
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {} # To construct ARNs correctly

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "security_compliance"
    }
  )
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Construct S3 bucket ARNs if names are provided
  config_s3_bucket_arn     = var.config_s3_bucket_name != "" ? "arn:${local.partition}:s3:::${var.config_s3_bucket_name}" : null
  cloudtrail_s3_bucket_arn = var.cloudtrail_s3_bucket_name != "" ? "arn:${local.partition}:s3:::${var.cloudtrail_s3_bucket_name}" : null

  # Standard ARNs for Security Hub
  aws_foundational_security_standard_arn = "arn:${local.partition}:securityhub:::ruleset/aws-foundational-security-best-practices/v/1.0.0"
  cis_aws_foundations_standard_arn       = "arn:${local.partition}:securityhub:${var.aws_region}::ruleset/cis-aws-foundations-benchmark/v/1.2.0" # Check latest version
}

# =============================================================================
# GuardDuty
# =============================================================================
resource "aws_guardduty_detector" "detector" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.guardduty_enable_s3_protection
    }

    kubernetes {
      audit_logs {
        enable = var.guardduty_enable_eks_protection
      }
    }

    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.guardduty_enable_malware_protection
        }
      }
    }
  }

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-guardduty-detector" })
}



# =============================================================================
# AWS Config
# Requires S3 bucket with appropriate policy allowing Config to write.
# Requires IAM Role allowing Config to describe resources.
# =============================================================================

# --- IAM Role for AWS Config ---
data "aws_iam_policy_document" "config_assume_role_policy" {
  count = var.enable_config ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config_role" {
  count = var.enable_config ? 1 : 0

  name               = "${var.project_name}-${var.environment}-config-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role_policy[0].json
  tags               = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-config-role" })
}

# Attach AWS Managed Policy for Config service role
resource "aws_iam_role_policy_attachment" "config_role_attachment" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSConfigRole" # Standard Config role policy
}


# --- AWS Config Recorder ---
resource "aws_config_configuration_recorder" "recorder" {
  count = var.enable_config ? 1 : 0

  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config_role[0].arn

  recording_group {
    all_supported                 = var.config_all_supported_resource_types
    include_global_resource_types = var.config_include_global_resource_types
    # Optionally specify resource_types = ["AWS::EC2::Instance", ...] if not recording all
  }
  depends_on = [aws_iam_role_policy_attachment.config_role_attachment]
}

# --- AWS Config Delivery Channel ---
resource "aws_config_delivery_channel" "channel" {
  count = var.enable_config && local.config_s3_bucket_arn != null ? 1 : 0

  name           = "${var.project_name}-${var.environment}-config-channel"
  s3_bucket_name = var.config_s3_bucket_name
  s3_key_prefix  = var.config_s3_key_prefix
  # s3_kms_key_arn = var.config_kms_key_arn # Optional KMS encryption for Config data in S3

  sns_topic_arn = var.config_sns_topic_arn # Optional SNS notifications

  # Optional snapshot delivery properties
  # snapshot_delivery_properties {
  #   delivery_frequency = "TwentyFour_Hours"
  # }

  depends_on = [aws_config_configuration_recorder.recorder]
}

# --- Start AWS Config Recorder ---
resource "aws_config_configuration_recorder_status" "recorder_status" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.recorder[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.channel]
}


# =============================================================================
# AWS CloudTrail
# Requires S3 bucket with appropriate policy allowing CloudTrail to write.
# =============================================================================

# --- Optional: CloudWatch Log Group for CloudTrail ---
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  count = var.enable_cloudtrail && var.cloudtrail_send_to_cloudwatch_logs ? 1 : 0

  name              = "/aws/cloudtrail/${var.project_name}-${var.environment}-trail"
  retention_in_days = var.cloudtrail_cloudwatch_logs_retention_days
  tags              = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-cloudtrail-lg" })
}

# --- Optional: IAM Role for CloudTrail -> CloudWatch Logs ---
data "aws_iam_policy_document" "cloudtrail_cloudwatch_assume_role_policy" {
  count = var.enable_cloudtrail && var.cloudtrail_send_to_cloudwatch_logs ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  count = var.enable_cloudtrail && var.cloudtrail_send_to_cloudwatch_logs ? 1 : 0

  name               = "${var.project_name}-${var.environment}-cloudtrail-cloudwatch-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_assume_role_policy[0].json
  tags               = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-cloudtrail-cloudwatch-role" })
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_policy_doc" {
  count = var.enable_cloudtrail && var.cloudtrail_send_to_cloudwatch_logs ? 1 : 0

  statement {
    sid    = "AllowCloudTrailToWriteLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.cloudtrail_log_group[0].arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  count = var.enable_cloudtrail && var.cloudtrail_send_to_cloudwatch_logs ? 1 : 0

  name   = "${var.project_name}-${var.environment}-cloudtrail-cloudwatch-policy"
  role   = aws_iam_role.cloudtrail_cloudwatch_role[0].id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_policy_doc[0].json
}

# --- CloudTrail Trail ---
resource "aws_cloudtrail" "trail" {
  count = var.enable_cloudtrail && local.cloudtrail_s3_bucket_arn != null ? 1 : 0

  name                          = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name                = var.cloudtrail_s3_bucket_name
  s3_key_prefix                 = var.cloudtrail_s3_key_prefix
  include_global_service_events = var.cloudtrail_include_global_service_events
  is_multi_region_trail         = var.cloudtrail_is_multi_region_trail
  enable_log_file_validation    = var.cloudtrail_enable_log_file_validation
  kms_key_id                    = var.cloudtrail_kms_key_arn # Optional KMS encryption

  # CloudWatch Logs Integration (Optional)
  cloud_watch_logs_group_arn = var.cloudtrail_send_to_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail_log_group[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.cloudtrail_send_to_cloudwatch_logs ? aws_iam_role.cloudtrail_cloudwatch_role[0].arn : null

  # Optional: Advanced Event Selectors (e.g., to include S3 Data Events - can be costly)
  # advanced_event_selector { ... }

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-trail" })

  depends_on = [
     aws_iam_role_policy.cloudtrail_cloudwatch_policy # Ensure role/policy exists if sending to CWL
  ]
}


# =============================================================================
# Security Hub
# =============================================================================
resource "aws_securityhub_account" "sh_account" {
  count = var.enable_security_hub ? 1 : 0
  # Enabling Security Hub - no complex config needed here for basic enablement
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enable_security_hub && var.security_hub_enable_default_standards ? 1 : 0

  standards_arn = local.aws_foundational_security_standard_arn
  depends_on = [aws_securityhub_account.sh_account]
}

resource "aws_securityhub_standards_subscription" "cis_foundations" {
  count = var.enable_security_hub && var.security_hub_enable_default_standards ? 1 : 0

  standards_arn = local.cis_aws_foundations_standard_arn
  depends_on = [aws_securityhub_account.sh_account]
}


# =============================================================================
# Inspector v2
# =============================================================================
resource "aws_inspector2_enabler" "inspector_enabler" {
  count = var.enable_inspector ? 1 : 0

  account_ids    = [local.account_id] # Enable for the current account
  resource_types = compact([          # Build list based on input flags
    var.inspector_scan_ec2 ? "EC2" : "",
    var.inspector_scan_ecr ? "ECR" : "",
    var.inspector_scan_lambda ? "LAMBDA" : ""
  ])
}


# =============================================================================
# Macie
# =============================================================================
resource "aws_macie2_account" "macie_account" {
  count = var.enable_macie ? 1 : 0

  finding_publishing_frequency = var.macie_finding_publishing_frequency
  status                       = "ENABLED" # Enable Macie
}

# Optional: Enable Automated Discovery
# resource "aws_macie2_classification_export_configuration" "automated_discovery" {
#   count = var.enable_macie && var.macie_enable_automated_discovery ? 1 : 0
#   # Configuration requires an S3 bucket and optional KMS key
#   # s3_destination {
#   #   bucket_name = var.macie_discovery_bucket_name
#   #   key_prefix  = "macie-auto-discovery/"
#   #   kms_key_arn = var.macie_kms_key_arn
#   # }
#   depends_on = [aws_macie2_account.macie_account]
# }
