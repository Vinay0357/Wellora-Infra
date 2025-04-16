# -----------------------------------------------------------------------------
# Input variables for the messaging module (SNS, SES)
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where messaging resources will be created"
  type        = string
}

# --- SES Configuration ---

variable "enable_ses" {
  description = "Set to true to configure SES domain identity"
  type        = bool
  default     = true
}

variable "ses_domain_name" {
  description = "The domain name to verify with SES for sending emails (e.g., wellora.com or mail.wellora.com)"
  type        = string
  default     = "" # MUST BE PROVIDED if enable_ses is true
}

variable "create_ses_configuration_set" {
  description = "Set to true to create a default SES Configuration Set for tracking/rules"
  type        = bool
  default     = true
}

# --- SNS Configuration ---

variable "enable_sns" {
  description = "Set to true to create SNS topics"
  type        = bool
  default     = true
}

variable "sns_topic_names" {
  description = "List of base names for SNS topics to create (prefix project-env will be added)"
  type        = list(string)
  default     = ["AppNotifications", "ProcessingEvents"] # Example topic names
}

variable "sns_kms_master_key_arn" {
  description = "ARN of the KMS key to use for SNS topic encryption (if null, uses AWS managed key 'alias/aws/sns')"
  type        = string
  default     = null
}

# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
