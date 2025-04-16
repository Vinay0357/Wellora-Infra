# -----------------------------------------------------------------------------
# Input variables for the security_groups module
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-southeast-2" # Defaulting to Sydney based on requirement
}

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created"
  type        = string
}

# --- Port Configuration ---
# These can be customized based on actual application needs

variable "alb_ingress_ports" {
  description = "List of ports the ALB should allow ingress traffic on from the internet"
  type        = list(number)
  default     = [80, 443] # Default HTTP and HTTPS
}

variable "app_port" {
  description = "The primary port the application instances listen on (e.g., for traffic from ALB)"
  type        = number
  default     = 8080 # Example application port
}

variable "db_port" {
  description = "The port the database instances listen on (e.g., 5432 for PostgreSQL, 3306 for MySQL, 6379 for Redis)"
  type        = number
  default     = 5432 # Example: PostgreSQL
}

variable "ssh_port" {
  description = "SSH port, typically used for bastion/admin access"
  type        = number
  default     = 22
}

# --- Access Control ---

variable "allow_all_internet_ingress_for_alb" {
  description = "Set to true to allow 0.0.0.0/0 and ::/0 on ALB ingress ports. Set to false to restrict to specific CIDRs if needed."
  type        = bool
  default     = true
}

variable "admin_access_cidrs" {
  description = "List of CIDR blocks allowed for administrative access (e.g., SSH to specific instances, VPN CIDR). This will ideally come from the VPN module later."
  type        = list(string)
  default     = [] # Default to empty, should be populated (e.g. ["YOUR_VPN_CIDR/_PREFIX"])
}

# --- Tags ---

variable "common_tags" {
  description = "Common tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
