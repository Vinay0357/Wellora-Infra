# -----------------------------------------------------------------------------
# Input variables for the security_compliance module
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project used in resource names/tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

# --- Service Enable Flags ---

variable "enable_guardduty" {
  description = "Set to true to enable Amazon GuardDuty"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Set to true to enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Set to true to enable AWS CloudTrail"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Set to true to enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "enable_inspector" {
  description = "Set to true to enable Amazon Inspector v2"
  type        = bool
  default     = true
}

variable "enable_macie" {
  description = "Set to true to enable Amazon Macie"
  type        = bool
  default     = true
}

# --- GuardDuty Configuration ---
variable "guardduty_enable_s3_protection" {
  description = "Enable GuardDuty S3 Protection feature"
  type        = bool
  default     = true
}
variable "guardduty_enable_eks_protection" {
  description = "Enable GuardDuty EKS Protection feature"
  type        = bool
  default     = true
}
variable "guardduty_enable_malware_protection" {
  description = "Enable GuardDuty Malware Protection feature"
  type        = bool
  default     = true
}
variable "guardduty_finding_publishing_frequency" {
  description = "Frequency for publishing GuardDuty findings (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "SIX_HOURS"
}

# --- AWS Config Configuration ---
variable "config_s3_bucket_name" {
  description = "Name of the S3 bucket for AWS Config delivery. Must exist and have correct policy."
  type        = string
  default     = "" # Required if enable_config is true. e.g., module.s3.config_log_bucket_id
}

variable "config_s3_key_prefix" {
  description = "Optional prefix for Config files in the S3 bucket"
  type        = string
  default     = "config"
}

variable "config_sns_topic_arn" {
  description = "ARN of the SNS topic for AWS Config notifications (Optional)"
  type        = string
  default     = null
}

variable "config_include_global_resource_types" {
  description = "Specifies whether AWS Config includes records for global resource types (e.g., IAM users)"
  type        = bool
  default     = true
}

variable "config_all_supported_resource_types" {
  description = "Specifies whether AWS Config records configuration changes for all supported resource types"
  type        = bool
  default     = true
}

# --- CloudTrail Configuration ---
variable "cloudtrail_s3_bucket_name" {
  description = "Name of the S3 bucket for CloudTrail log delivery. Must exist and have correct policy."
  type        = string
  default     = "" # Required if enable_cloudtrail is true. e.g., module.s3.cloudtrail_log_bucket_id
}

variable "cloudtrail_s3_key_prefix" {
  description = "Optional prefix for CloudTrail logs in the S3 bucket"
  type        = string
  default     = "cloudtrail"
}

variable "cloudtrail_kms_key_arn" {
  description = "ARN of the KMS key for CloudTrail log encryption (Optional, if null uses SSE-S3)"
  type        = string
  default     = null
}

variable "cloudtrail_enable_log_file_validation" {
  description = "Enable log file integrity validation for CloudTrail"
  type        = bool
  default     = true
}

variable "cloudtrail_include_global_service_events" {
  description = "Specifies whether the trail is publishing events from global services such as IAM to the log files."
  type        = bool
  default     = true
}

variable "cloudtrail_is_multi_region_trail" {
  description = "Specifies whether the trail is created in the current region or in all regions."
  type        = bool
  default     = true # Common practice to have one multi-region trail
}

variable "cloudtrail_send_to_cloudwatch_logs" {
  description = "Enable sending CloudTrail events to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "cloudtrail_cloudwatch_logs_retention_days" {
  description = "Retention period in days for the CloudTrail CloudWatch log group (0 for indefinite)"
  type        = number
  default     = 365 # Retain for 1 year
}

# --- Security Hub Configuration ---
variable "security_hub_enable_default_standards" {
  description = "Enable AWS Foundational Security Best Practices and CIS AWS Foundations Benchmark standards"
  type        = bool
  default     = true
}

# --- Inspector v2 Configuration ---
variable "inspector_scan_ec2" {
  description = "Enable EC2 scanning in Inspector v2"
  type        = bool
  default     = true
}
variable "inspector_scan_ecr" {
  description = "Enable ECR scanning in Inspector v2"
  type        = bool
  default     = true
}
variable "inspector_scan_lambda" {
  description = "Enable Lambda scanning in Inspector v2"
  type        = bool
  default     = false # Enable if using Lambda extensively
}

# --- Macie Configuration ---
# Macie configuration can be complex (classification jobs etc.). This focuses on enabling it.
variable "macie_finding_publishing_frequency" {
  description = "Frequency for publishing Macie findings (FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS)"
  type        = string
  default     = "SIX_HOURS"
}
variable "macie_enable_automated_discovery" {
  description = "Set to true to enable automated sensitive data discovery"
  type        = bool
  default     = false # Can incur costs, enable deliberately
}


# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}