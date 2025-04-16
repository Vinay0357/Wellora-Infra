# -----------------------------------------------------------------------------
# Input variables for the iam module
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

# --- Role/Policy Creation Flags ---
variable "create_eks_roles" {
  description = "Set to true to create EKS Cluster and Node roles"
  type        = bool
  default     = true # Assuming EKS is used based on diagram
}

variable "create_app_task_role" {
  description = "Set to true to create a general IAM role for application tasks/pods"
  type        = bool
  default     = true
}

variable "attach_ssm_policy_to_nodes" {
  description = "Set to true to attach AmazonSSMManagedInstanceCore policy to EKS Node role"
  type        = bool
  default     = true # Recommended for management via SSM
}

variable "attach_cloudwatch_agent_policy_to_nodes" {
  description = "Set to true to attach CloudWatchAgentServerPolicy policy to EKS Node role"
  type        = bool
  default     = false # Enable if using CloudWatch agent for detailed metrics/logs
}

# --- External Resource Identifiers (to be passed from other modules) ---

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider (required for IRSA - IAM Roles for Service Accounts)"
  type        = string
  default     = "" # Must be provided by the EKS module if using IRSA
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC Provider (required for IRSA assume role policy)"
  type        = string
  default     = "" # Must be provided by the EKS module if using IRSA (strip https://)
}

variable "s3_general_bucket_arns" {
  description = "List of ARNs for general S3 buckets the application needs access to (e.g., raw audio, transcripts)"
  type        = list(string)
  default     = [] # e.g., ["arn:aws:s3:::wellora-prod-raw-audio", "arn:aws:s3:::wellora-prod-transcripts"]
}

variable "s3_static_assets_bucket_arn" {
  description = "ARN of the S3 bucket for static assets (may need different permissions)"
  type        = string
  default     = "" # e.g., "arn:aws:s3:::wellora-prod-static-assets"
}

variable "dynamodb_table_arns" {
  description = "List of ARNs for DynamoDB tables the application needs access to"
  type        = list(string)
  default     = [] # e.g., ["arn:aws:dynamodb:ap-southeast-2:123456789012:table/WelloraAppData"]
}

variable "kms_key_arns_for_encryption" {
  description = "List of KMS Key ARNs used for encrypting/decrypting data (e.g., S3, HealthLake)"
  type        = list(string)
  default     = [] # Provide specific key ARNs if using CMKs
}

variable "k8s_service_account_name" {
  description = "Optional: Kubernetes Service Account name to scope the EKS OIDC trust relationship to. Use '*' for any service account in any namespace (less secure)."
  type        = string
  default     = "*" # Default allows any service account - refine if needed for better security
}

# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply to all IAM resources that support tagging"
  type        = map(string)
  default     = {}
}
