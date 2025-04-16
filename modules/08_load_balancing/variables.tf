# -----------------------------------------------------------------------------
# Input variables for the load_balancing module (ALB)
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
  description = "ID of the VPC where the ALB and Target Group will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be deployed"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "The ID of the security group to attach to the Application Load Balancer"
  type        = list(string) # Security groups for ALB must be a list
}

variable "alb_name" {
  description = "Name for the Application Load Balancer (defaults to project-env-alb)"
  type        = string
  default     = "" # If empty, will be constructed
}

variable "is_internal_alb" {
  description = "Set to true if the ALB should be internal, false for internet-facing"
  type        = bool
  default     = false # Diagram shows internet-facing
}

variable "enable_alb_deletion_protection" {
  description = "Enable deletion protection for the ALB"
  type        = bool
  default     = true # Recommended for prod
}

# --- Target Group & Health Check ---

variable "target_group_port" {
  description = "The port on which targets (pods/instances) receive traffic. Should match the application port."
  type        = number
  default     = 8080 # Example, ensure this matches your app and app SG rules
}

variable "target_group_protocol" {
  description = "Protocol for traffic to targets (HTTP or HTTPS)"
  type        = string
  default     = "HTTP" # Traffic from ALB to Pods often HTTP internally
}

variable "target_type" {
  description = "Target type ('instance', 'ip', 'lambda'). Use 'ip' for EKS pods."
  type        = string
  default     = "ip" # For EKS
}

variable "health_check_path" {
  description = "The destination for health checks (e.g., /health)"
  type        = string
  default     = "/" # Default path, customize for your app's health endpoint
}

variable "health_check_port" {
  description = "The port used for health checks ('traffic-port' or a specific port)"
  type        = string
  default     = "traffic-port" # Uses the target_group_port
}

variable "health_check_protocol" {
  description = "Protocol for health checks (HTTP or HTTPS)"
  type        = string
  default     = "HTTP" # Match target protocol usually
}

variable "health_check_interval" {
  description = "Approximate interval in seconds between health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout in seconds for health check response"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful checks to declare healthy"
  type        = number
  default     = 3
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed checks to declare unhealthy"
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "HTTP codes to use when checking for a successful response from a target."
  type        = string
  default     = "200" # Match only HTTP 200, or use "200-299" etc.
}

# --- Listeners ---

variable "enable_http_listener" {
  description = "Enable listener for HTTP traffic on port 80"
  type        = bool
  default     = true
}

variable "enable_https_listener" {
  description = "Enable listener for HTTPS traffic on port 443 (requires ACM certificate)"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener. Required if enable_https_listener is true."
  type        = string
  default     = null # MUST BE PROVIDED for HTTPS
}

variable "ssl_policy" {
  description = "Security policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-2016-08" # AWS recommended default
}

variable "http_to_https_redirect" {
  description = "Set to true to configure the HTTP listener to redirect to HTTPS. Requires both listeners enabled."
  type        = bool
  default     = true
}

# --- Access Logs ---

variable "enable_alb_access_logs" {
  description = "Enable access logging for the ALB"
  type        = bool
  default     = true
}

variable "access_logs_s3_bucket_name" {
  description = "Name of the S3 bucket where ALB access logs should be stored. Must exist and have correct policy."
  type        = string
  default     = "" # Should be passed from S3 module output or root config
}

variable "access_logs_s3_prefix" {
  description = "Optional prefix for access log files within the S3 bucket"
  type        = string
  default     = "alb-logs"
}

# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
