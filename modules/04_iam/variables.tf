# -----------------------------------------------------------------------------
# Input variables for the IAM module
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name prefix"
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
  default     = true
}

variable "eks_roles" {
  description = "Map of EKS cluster roles to create"
  type = map(object({
    rolename = string
  }))
  default = {
    eks_cluster_role1 = {
      rolename = "eks-cluster-role"
    }
  }
}

variable "eks_node_roles" {
  description = "Map of EKS node roles to create"
  type = map(object({
    rolename = string
  }))
  default = {
    eks_node_role1 = {
      # rolename = "${var.project_name}-${var.environment}-eks-node-role"
      rolename = "eks-node-role"
    }
  }
}

variable "create_app_task_role" {
  description = "Set to true to create a general IAM role for application tasks/pods"
  type        = bool
  default     = true
}

variable "attach_ssm_policy_to_nodes" {
  description = "Set to true to attach AmazonSSMManagedInstanceCore policy to EKS Node role"
  type        = bool
  default     = true
}

variable "attach_cloudwatch_agent_policy_to_nodes" {
  description = "Set to true to attach CloudWatchAgentServerPolicy policy to EKS Node role"
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider (required for IRSA - IAM Roles for Service Accounts)"
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC Provider (required for IRSA assume role policy)"
  type        = string
  default     = ""
}

variable "s3_general_bucket_arns" {
  description = "List of ARNs for general S3 buckets the application needs access to"
  type        = list(string)
  default     = []
}

variable "s3_static_assets_bucket_arn" {
  description = "ARN of the S3 bucket for static assets"
  type        = string
  default     = ""
}

variable "dynamodb_table_arns" {
  description = "List of ARNs for DynamoDB tables the application needs access to"
  type        = list(string)
  default     = []
}

variable "kms_key_arns_for_encryption" {
  description = "List of KMS Key ARNs used for encrypting/decrypting data"
  type        = list(string)
  default     = []
}

variable "k8s_service_account_name" {
  description = "Kubernetes Service Account name for EKS OIDC trust relationship"
  type        = string
  default     = "*"
}

variable "iam_roles" {
  description = "Map of IAM roles to create, with assume role policy and optional tags"
  type = map(object({
    rolename              = string
    assume_role_policy    = string
    managed_policy_arns   = optional(list(string), [])
    inline_policies       = optional(map(string), {})
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}