# -----------------------------------------------------------------------------
# Input variables for the admin_access module (AWS Client VPN)
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the Client VPN will be associated"
  type        = string
}

variable "vpn_target_subnet_ids" {
  description = "List of subnet IDs to associate the Client VPN endpoint with. Must provide at least two across different AZs for HA."
  type        = list(string) # e.g., module.networking.private_app_subnet_ids
}

variable "vpn_endpoint_security_group_ids" {
  description = "List of security group IDs to apply to the Client VPN endpoint ENIs."
  type        = list(string)
  # Example: [module.security_groups.vpn_endpoint_sg_id] - Requires creating a dedicated SG
  # Or use a default SG allowing necessary outbound from VPN CIDR initially.
}

# --- Client VPN Configuration ---

variable "client_cidr_block" {
  description = "The IPv4 CIDR range from which client IP addresses will be assigned. Must not overlap with VPC CIDR. Min /22."
  type        = string
  default     = "10.99.0.0/16" # Example CIDR, ensure it doesn't overlap
}

variable "server_certificate_arn" {
  description = "ARN of the ACM certificate to be used as the server certificate (must be in the same region)."
  type        = string
  # default = "" # MUST BE PROVIDED
}

variable "authentication_type" {
  description = "Client authentication type ('certificate-authentication', 'directory-service-authentication', 'federated-authentication')."
  type        = string
  default     = "certificate-authentication" # Using mutual certificate auth
}

variable "client_certificate_arn" {
  description = "ARN of the ACM certificate to be used as the client root certificate (required for 'certificate-authentication')."
  type        = string
  default     = null # MUST BE PROVIDED if using certificate-authentication
}

# Add variables for directory_id or saml_provider_arn if using other auth types

variable "split_tunnel_enabled" {
  description = "Indicates whether split-tunnel is enabled on the Client VPN endpoint."
  type        = bool
  default     = true # Typically true - only route traffic destined for VPC through VPN
}

variable "dns_servers" {
  description = "IP addresses of DNS servers to push to clients (Optional)."
  type        = list(string)
  default     = null # Uses default VPC DNS resolver if null
}

variable "enable_connection_logging" {
  description = "Enable logging of connection data to CloudWatch Logs."
  type        = bool
  default     = true
}

# --- Authorization ---
variable "authorize_all_users_to_vpc" {
  description = "Authorize all authenticated VPN users access to the entire associated VPC CIDR."
  type        = bool
  default     = true # Set to false to configure more granular group-based rules if needed
}

variable "vpc_cidr_for_authorization" {
  description = "The VPC CIDR block to authorize access to (required if authorize_all_users_to_vpc is true)."
  type        = string
  # default = "" # Should be passed from networking module, e.g., module.networking.vpc_cidr_block
}


# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
