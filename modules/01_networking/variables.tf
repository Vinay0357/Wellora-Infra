# -----------------------------------------------------------------------------
# variables for the networking module
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-southeast-2" # Defaulting to Sydney based on requirement
}

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
  default     = "wellora"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "prod" # Assuming prod for now, can be overridden
}

variable "vpc_cidr" {
  description = "The primary CIDR block for the VPC"
  type        = string
  default     = "10.98.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones to use"
  type        = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  # Note: It's often better to let AWS choose AZs or pass specific ones like:
  # default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
  # Using data source in main.tf to get available zones is more flexible if specific zones aren't required.
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.98.1.0/24", "10.98.2.0/24", "10.98.3.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDR blocks for the private application subnets (one per AZ)"
  type        = list(string)
  default     = ["10.98.10.0/23", "10.98.12.0/23", "10.98.14.0/23"]
}

variable "private_db_subnet_cidrs" {
  description = "List of CIDR blocks for the private database subnets (one per AZ)"
  type        = list(string)
  default     = ["10.98.20.0/24", "10.98.21.0/24", "10.98.22.0/24"]
}

variable "enable_nat_gateway" {
  description = "Should NAT Gateways be created (requires public subnets)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Set to true to create only one NAT Gateway (not recommended for prod)"
  type        = bool
  default     = false # Default is one NAT Gateway per AZ for HA
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
