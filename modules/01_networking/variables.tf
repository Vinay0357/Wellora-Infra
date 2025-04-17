variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs to use. If empty, will fetch dynamically."
  type        = list(string)
  default     = []
}

variable "number_of_azs_to_use" {
  description = "Number of AZs to select"
  type        = number
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDRs for private application subnets"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDRs for private database subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway?"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Single NAT gateway?"
  type        = bool
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames?"
  type        = bool
}

variable "enable_dns_support" {
  description = "Enable DNS support?"
  type        = bool
}

variable "common_tags" {
  description = "Tags to apply"
  type        = map(string)
}
