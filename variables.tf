# wellora-infra/variables.tf


variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Base name for the project"
  type        = string
  default     = "wellora"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "prod" # Or perhaps "dev" for initial testing
}

variable "db_password" {
  description = "RDS master password (should be set via environment variable TF_VAR_db_password or other secure method)"
  type        = string
  sensitive   = true
  default     = null # MUST be provided securely
}

variable "domain_name" {
  description = "The primary domain name for the application (e.g., app.wellora.com)"
  type        = string
  # no default - must be provided
}

variable "ses_sending_domain" {
  description = "Domain name used for sending emails via SES (e.g., mail.wellora.com)"
  type        = string
  # no default - must be provided
}

variable "vpn_server_cert_arn" {
  description = "ARN of the ACM certificate for the Client VPN Server (in deployment region)"
  type        = string
  # no default - must be provided
}

variable "vpn_client_cert_arn" {
  description = "ARN of the ACM certificate for the Client VPN Client Root CA (in deployment region, for mutual auth)"
  type        = string
  # no default - must be provided
}

variable "cloudfront_acm_cert_arn_us_east_1" {
  description = "ARN of the ACM certificate for CloudFront (MUST be in us-east-1)"
  type        = string
  # no default - must be provided
}

variable "waf_acl_arn_us_east_1" {
  description = "ARN of the WAFv2 WebACL for CloudFront (MUST be in us-east-1)"
  type        = string
  default     = null # Make optional or provide a default/lookup if always using one
}

# Add any other root-level variables needed (e.g., specific CIDRs if not using module defaults)
# --- (Root variables.tf needs definition for vpn_cidr_blocks if used like above) ---
# variable "vpn_cidr_blocks" {
#   description = "CIDR blocks allowed for admin access"
#   type        = list(string)
#   default     = [] # MUST BE OVERRIDDEN FOR ADMIN ACCESS TO WORK
# }

# variable "db_password" {
#   description = "RDS master password (should be set via environment variable TF_VAR_db_password)"
#   type        = string
#   sensitive   = true
#   default     = null # Ensure it must be provided externally
# }

# --- Define var.domain_name in root variables.tf ---
# variable "domain_name" {
#   description = "The domain name for the application (e.g., wellora.example.com)"
#   type        = string
# }

# --- Define required us-east-1 resources/ARNs ---
variable "domain_name" {
  description = "The primary domain name for the application (e.g., app.wellora.com)"
  type        = string
}
variable "cloudfront_acm_cert_arn_us_east_1" {
  description = "ARN of the ACM certificate for CloudFront (MUST be in us-east-1)"
  type        = string
}
variable "waf_acl_arn_us_east_1" {
  description = "ARN of the WAFv2 WebACL for CloudFront (MUST be in us-east-1)"
  type        = string
  default     = null # Make optional or provide a default/lookup
}

# --- (Root variables.tf needs definition for ses_sending_domain) ---
# variable "ses_sending_domain" {
#   description = "Domain name used for sending emails via SES"
#   type        = string
#   # Example: default = "mail.wellora.com"
# }

# --- Define ACM Certificate ARNs (Must exist in the same region) ---
variable "vpn_server_cert_arn" {
  description = "ARN of the ACM certificate for the Client VPN Server"
  type        = string
}
variable "vpn_client_cert_arn" {
  description = "ARN of the ACM certificate for the Client VPN Client Root CA (for mutual auth)"
  type        = string
}