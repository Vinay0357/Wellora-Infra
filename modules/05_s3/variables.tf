# -----------------------------------------------------------------------------
# Input variables for the S3 module
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
  description = "AWS region where resources will be created (used for constructing ARNs/policies)"
  type        = string
}

# --- Bucket Configuration ---

variable "static_assets_bucket_name_suffix" {
  description = "Suffix for the static assets bucket name (full name will be project-env-suffix)"
  type        = string
  default     = "static-assets"
}

variable "raw_audio_bucket_name_suffix" {
  description = "Suffix for the raw audio bucket name"
  type        = string
  default     = "raw-audio"
}

variable "transcripts_bucket_name_suffix" {
  description = "Suffix for the transcripts bucket name"
  type        = string
  default     = "transcripts"
}

variable "force_destroy_buckets" {
  description = "Set to true to force destroy S3 buckets (deletes all objects) on terraform destroy. USE WITH CAUTION, especially in prod."
  type        = bool
  default     = false
}

# --- Security & Compliance ---

variable "enable_versioning" {
  description = "Enable versioning for all created buckets (recommended)"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Apply default block public access settings to data buckets (raw audio, transcripts)"
  type        = bool
  default     = true
}

variable "static_assets_block_public_access" {
  description = "Apply default block public access settings to the static assets bucket (Set to false only if intentionally public, prefer CloudFront OAI/OAC)"
  type        = bool
  default     = true # Default to blocking public access, rely on CloudFront OAI/OAC or signed URLs
}

variable "encryption_type" {
  description = "Server-side encryption type ('AES256' for SSE-S3, 'aws:kms' for SSE-KMS)"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "Allowed encryption types are AES256 or aws:kms."
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for SSE-KMS encryption (required if encryption_type is 'aws:kms')"
  type        = string
  default     = null # Must be provided if using SSE-KMS
}

# --- Access Logging ---

variable "enable_access_logging" {
  description = "Enable S3 server access logging for the buckets"
  type        = bool
  default     = true # Recommended practice
}

variable "create_access_log_bucket" {
  description = "Set to true to create a dedicated bucket for access logs within this module"
  type        = bool
  default     = true # Creates a separate log bucket if logging is enabled
}

variable "access_log_bucket_name_suffix" {
  description = "Suffix for the access log bucket name (if created by module)"
  type        = string
  default     = "access-logs"
}

variable "existing_access_log_bucket_id" {
  description = "The ID (name) of an existing S3 bucket to send access logs to (used if create_access_log_bucket is false)"
  type        = string
  default     = ""
}

variable "log_file_prefix_static" {
  description = "Prefix for log files stored in the access log bucket for the static assets bucket"
  type        = string
  default     = "logs/static-assets/"
}
variable "log_file_prefix_raw_audio" {
  description = "Prefix for log files stored in the access log bucket for the raw audio bucket"
  type        = string
  default     = "logs/raw-audio/"
}
variable "log_file_prefix_transcripts" {
  description = "Prefix for log files stored in the access log bucket for the transcripts bucket"
  type        = string
  default     = "logs/transcripts/"
}


# --- Lifecycle Rules ---

variable "enable_lifecycle_rules" {
  description = "Enable basic lifecycle rules (transition to IA, expiration) for data buckets"
  type        = bool
  default     = true
}

variable "ia_transition_days" {
  description = "Number of days after which to transition objects to STANDARD_IA (or INTELLIGENT_TIERING)"
  type        = number
  default     = 30
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which to expire noncurrent object versions"
  type        = number
  default     = 90
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days after which to abort incomplete multipart uploads"
  type        = number
  default     = 7
}

# --- CORS Configuration (for Static Assets) ---
variable "enable_cors_static_assets" {
  description = "Enable CORS configuration for the static assets bucket"
  type        = bool
  default     = false # Enable only if needed (e.g., web fonts, direct API access)
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS configuration"
  type        = list(string)
  default     = ["*"] # BE CAREFUL WITH WILDCARD IN PRODUCTION
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for CORS configuration"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS configuration"
  type        = list(string)
  default     = ["*"]
}

variable "cors_max_age_seconds" {
  description = "Specifies time in seconds that browser can cache the response for a preflight request"
  type        = number
  default     = 3000
}

# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
