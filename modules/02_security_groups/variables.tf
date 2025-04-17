# -----------------------------------------------------------------------------
# Input variables for security_groups module
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
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_ingress_ports" {
  description = "ALB allowed ingress ports"
  type        = list(number)
  default     = [80, 443]
}

variable "app_port" {
  description = "Application service port"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "ssh_port" {
  description = "SSH port for admin access"
  type        = number
  default     = 22
}

variable "allow_all_internet_ingress_for_alb" {
  description = "Whether ALB allows 0.0.0.0/0"
  type        = bool
  default     = true
}

variable "admin_access_cidrs" {
  description = "Admin access CIDRs"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
