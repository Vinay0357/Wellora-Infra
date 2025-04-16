# -----------------------------------------------------------------------------
# Input variables for the edge module (CloudFront, WAF association)
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

# --- Origin Details (from other modules) ---

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (ALB) origin"
  type        = string
}

variable "s3_static_assets_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket for static assets origin"
  type        = string
  # Example: "mybucket.s3.ap-southeast-2.amazonaws.com"
}

variable "s3_static_assets_bucket_id" {
  description = "The ID (name) of the S3 bucket for static assets origin"
  type        = string
}

# --- CloudFront Distribution Settings ---

variable "domain_aliases" {
  description = "List of custom domain names (aliases) to associate with the CloudFront distribution (e.g., ['app.example.com'])"
  type        = list(string)
  default     = []
}

variable "cloudfront_acm_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 region for the CloudFront distribution aliases. Required if domain_aliases is set."
  type        = string
  default     = null # MUST BE PROVIDED if using custom domains
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100" # Use PriceClass_All for best performance globally
}

variable "default_root_object" {
  description = "Default object to serve when the root URL is requested (e.g., index.html)"
  type        = string
  default     = "index.html"
}

variable "api_path_pattern" {
  description = "Path pattern for requests that should be forwarded to the ALB origin (e.g., /api/*)"
  type        = string
  default     = "/api/*"
}

# --- WAF Integration ---

variable "enable_waf" {
  description = "Set to true to associate a WAFv2 Web ACL with the CloudFront distribution"
  type        = bool
  default     = true
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL (must be in us-east-1 / scope CLOUDFRONT). Required if enable_waf is true."
  type        = string
  default     = null # MUST BE PROVIDED if enable_waf is true
}

# --- Logging ---

variable "enable_cloudfront_logging" {
  description = "Enable standard logging for the CloudFront distribution"
  type        = bool
  default     = true
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket for storing CloudFront logs (e.g., from S3 module output). Must NOT have '.' in the name."
  type        = string
  default     = "" # e.g., module.s3.access_log_bucket_id
}

variable "log_prefix" {
  description = "Optional prefix for CloudFront log files within the S3 bucket"
  type        = string
  default     = "cloudfront-logs/"
}

variable "log_include_cookies" {
  description = "Specifies whether you want CloudFront to include cookies in access logs"
  type        = bool
  default     = false
}

# --- Cache Policies (Using Managed Policies as examples) ---

variable "static_assets_cache_policy_id" {
  description = "ID of the Cache Policy for static assets (S3 origin). Default uses Managed-CachingOptimized."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6" # ID for Managed-CachingOptimized
}

variable "api_cache_policy_id" {
  description = "ID of the Cache Policy for API requests (ALB origin). Default uses Managed-CachingDisabled."
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # ID for Managed-CachingDisabled
}

variable "api_origin_request_policy_id" {
  description = "ID of the Origin Request Policy for API requests (ALB origin). Default uses Managed-AllViewer."
  type        = string
  default     = "216adef6-5c7f-47e4-b989-5492eafa07d3" # ID for Managed-AllViewer (forwards all headers, cookies, query strings) - REVIEW SECURITY
}


# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
