# -----------------------------------------------------------------------------
# Input variables for the compute module (EKS, ECR)
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
  description = "AWS region where resources will be created"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS control plane and worker nodes (usually App tier subnets)"
  type        = list(string)
}

# If using public subnets for public API endpoint or public nodes (less common for app tier)
variable "public_subnet_ids" {
  description = "List of public subnet IDs (used for public API endpoint if enabled)"
  type        = list(string)
  default     = []
}

# --- IAM Roles (from IAM Module) ---

variable "eks_cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster control plane"
  type        = string
}

variable "eks_node_role_arn" {
  description = "ARN of the IAM role for the EKS worker nodes"
  type        = string
}

# --- EKS Cluster Configuration ---

variable "cluster_name" {
  description = "Name for the EKS cluster"
  type        = string
  default     = "" # If empty, will be constructed like project-env-eks
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster control plane"
  type        = string
  default     = "1.29" # Check AWS for latest supported versions
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true # Allows kubectl access from outside VPC. Consider restricting CIDRs or disabling.
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks to allow access to the public endpoint. Use ['0.0.0.0/0'] for open access (if public access enabled)."
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production!
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled (for access from within VPC)"
  type        = bool
  default     = true # Recommended for nodes/pods communication within VPC
}

variable "cluster_enabled_log_types" {
  description = "List of EKS control plane log types to enable (api, audit, authenticator, controllerManager, scheduler)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"] # Enable all for visibility
}

variable "cluster_security_group_ids" {
  description = "List of security group IDs to associate with the EKS control plane ENIs. If empty, a default one will be created."
  type        = list(string)
  default     = []
}

# --- EKS Node Group Configuration ---

variable "nodegroup_name" {
  description = "Name for the default EKS managed node group"
  type        = string
  default     = "default-workers" # Can create multiple node groups
}

variable "nodegroup_instance_types" {
  description = "List of instance types for the EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"] # Example, choose based on workload
}

variable "nodegroup_scaling_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "nodegroup_scaling_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "nodegroup_scaling_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "nodegroup_ami_type" {
  description = "AMI type for the worker nodes (e.g., AL2_x86_64, BOTTLEROCKET_x86_64)"
  type        = string
  default     = "AL2_x86_64"
}

variable "nodegroup_capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "nodegroup_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50 # Example size
}

# --- ECR Configuration ---

variable "create_ecr_repos" {
  description = "Set to true to create ECR repositories defined in this module"
  type        = bool
  default     = true
}

variable "ecr_repository_names" {
  description = "List of base names for ECR repositories to create (prefix project/env will be added)"
  type        = list(string)
  default     = ["frontend-app", "processing-service", "realtime-service"] # Example repo names based on diagram blocks
}

variable "ecr_image_tag_mutability" {
  description = "Mutability of image tags in ECR ('MUTABLE' or 'IMMUTABLE')"
  type        = string
  default     = "IMMUTABLE" # Recommended best practice
}

variable "ecr_scan_on_push" {
  description = "Enable ECR image scanning on push"
  type        = bool
  default     = true
}


# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
