# -----------------------------------------------------------------------------
# Input variables for the vpc_endpoints module
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
  description = "The ID of the VPC where the endpoints will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where Interface Endpoints should be deployed (usually App tier subnets)"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of IDs of the private route tables to associate with Gateway Endpoints"
  type        = list(string)
}

variable "app_tier_security_group_id" {
  description = "The ID of the Application Tier security group, used to allow traffic to endpoints"
  type        = string
}

# --- Endpoint Enable Flags ---

variable "create_s3_gateway_endpoint" {
  description = "Set to true to create a Gateway endpoint for S3"
  type        = bool
  default     = true
}

variable "create_dynamodb_gateway_endpoint" {
  description = "Set to true to create a Gateway endpoint for DynamoDB"
  type        = bool
  default     = true
}

variable "create_transcribe_interface_endpoint" {
  description = "Set to true to create an Interface endpoint for Transcribe"
  type        = bool
  default     = true
}

variable "create_bedrock_interface_endpoint" {
  description = "Set to true to create an Interface endpoint for Bedrock Runtime"
  type        = bool
  default     = true
}

variable "create_healthlake_interface_endpoint" {
  description = "Set to true to create an Interface endpoint for HealthLake"
  type        = bool
  default     = true # Based on diagram
}

variable "create_ecr_interface_endpoints" {
  description = "Set to true to create Interface endpoints for ECR API and DKR (needed for ECS/EKS)"
  type        = bool
  default     = true
}

variable "create_logs_interface_endpoint" {
  description = "Set to true to create an Interface endpoint for CloudWatch Logs"
  type        = bool
  default     = true
}

variable "create_ssm_interface_endpoints" {
  description = "Set to true to create Interface endpoints for SSM (ssm, ssmmessages, ec2messages)"
  type        = bool
  default     = true # Recommended for instance management
}

# --- Tags ---

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}


variable "interface_endpoints_enabled" {
  description = "Map of interface endpoints to enable"
  type        = map(bool)
  default     = {
    transcribe  = false
    bedrock     = false
    healthlake  = false
    ecr_api     = false
    ecr_dkr     = false
    logs        = false
    s3_interface = false
    ssm         = false
    ssmmessages = false
    ec2messages = false
  }
}
