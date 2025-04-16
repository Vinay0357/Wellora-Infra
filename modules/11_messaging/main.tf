# -----------------------------------------------------------------------------
# Messaging Module - Main Configuration (SES Domain Identity, SNS Topics)
# -----------------------------------------------------------------------------

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "messaging"
    }
  )

  ses_enabled = var.enable_ses && var.ses_domain_name != ""
  sns_enabled = var.enable_sns && length(var.sns_topic_names) > 0

  # Construct full SNS topic names
  sns_topic_full_names = { for name in var.sns_topic_names : name => "${var.project_name}-${var.environment}-${name}" }

  # Determine KMS key ID for SNS (use default if specific ARN not provided)
  sns_kms_key_id = var.sns_kms_master_key_arn == null ? "alias/aws/sns" : var.sns_kms_master_key_arn

}

# =============================================================================
# AWS SES (Simple Email Service) Configuration
# =============================================================================

# --- SES Domain Identity ---
# Registers the domain with SES
resource "aws_ses_domain_identity" "domain" {
  count = local.ses_enabled ? 1 : 0

  domain = var.ses_domain_name
}

# --- SES DKIM Tokens ---
# Generates DKIM tokens. CNAME records need to be created in DNS manually.
resource "aws_ses_domain_dkim" "dkim" {
  count = local.ses_enabled ? 1 : 0

  domain = aws_ses_domain_identity.domain[0].domain
}

# --- SES Domain Identity Verification ---
# Optional resource to wait for DNS records to be propagated and verification to complete.
# Requires the DNS records (TXT for domain, CNAMEs for DKIM) to be created externally.
# resource "aws_ses_domain_identity_verification" "verification" {
#   count = local.ses_enabled ? 1 : 0
#   domain = aws_ses_domain_identity.domain[0].id
#
#   # Terraform will wait for verification for up to this duration
#   timeouts {
#     create = "30m"
#   }
#
#   depends_on = [
#     aws_ses_domain_dkim.dkim
#     # Add explicit dependency on the Route53 records if managed by Terraform
#   ]
# }


# --- SES Configuration Set (Optional) ---
resource "aws_ses_configuration_set" "config_set" {
  count = local.ses_enabled && var.create_ses_configuration_set ? 1 : 0

  name = "${var.project_name}-${var.environment}-default-configset"

  # Optional: Add tracking options, delivery options, reputation metrics etc.
  # tracking_options {
  #   custom_redirect_domain = "tracking.example.com"
  # }
}


# =============================================================================
# AWS SNS (Simple Notification Service) Configuration
# =============================================================================

resource "aws_sns_topic" "topics" {
  # Create a topic for each name in the input map
  for_each = local.sns_enabled ? local.sns_topic_full_names : {}

  name              = each.value # Use the constructed full name
  kms_master_key_id = local.sns_kms_key_id # Enable encryption

  # Optional: Define delivery policy, FIFO settings, etc.
  # fifo_topic = false
  # content_based_deduplication = false

  tags = merge(local.module_tags, {
    Name = each.value
  })
}

# --- SNS Topic Policy (Example: Allow CloudWatch Events - Optional) ---
# Note: Application publishing access should typically be granted via IAM Role policies
# data "aws_iam_policy_document" "sns_topic_policy_example" {
#   # Policy allowing CloudWatch Events to publish to this topic
#   statement {
#     sid = "AllowCloudWatchEvents"
#     actions = ["sns:Publish"]
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["events.amazonaws.com"]
#     }
#     resources = [aws_sns_topic.topics["YourTopicKey"].arn] # Reference specific topic ARN
#   }
#   # Add other statements if needed (e.g., allowing S3 event notifications)
# }

# resource "aws_sns_topic_policy" "default" {
#   for_each = local.sns_enabled ? local.sns_topic_full_names : {}
#   arn = aws_sns_topic.topics[each.key].arn
#   policy = data.aws_iam_policy_document.sns_topic_policy_example.json # Adjust policy as needed
# }
