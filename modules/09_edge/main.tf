# -----------------------------------------------------------------------------
# Edge Module - Main Configuration (CloudFront Distribution)
# -----------------------------------------------------------------------------
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1" # Alias provider for resources required in us-east-1 (ACM Cert Lookup, WAFv2 Web ACL Lookup)
}

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "edge"
    }
  )

  # Origin IDs
  s3_origin_id = "${var.project_name}-${var.environment}-s3-origin"
  alb_origin_id = "${var.project_name}-${var.environment}-alb-origin"

  # Logging configuration block only if logging enabled and bucket name provided
  logging_config = var.enable_cloudfront_logging && var.log_bucket_name != "" ? {
    include_cookies = var.log_include_cookies
    bucket          = "${var.log_bucket_name}.s3.amazonaws.com" # Use bucket domain name format
    prefix          = var.log_prefix
    } : null

  # Viewer certificate block only if aliases and certificate ARN are provided
  viewer_certificate_config = length(var.domain_aliases) > 0 && var.cloudfront_acm_certificate_arn != null ? {
    acm_certificate_arn      = var.cloudfront_acm_certificate_arn
    ssl_support_method       = "sni-only" # Recommended
    minimum_protocol_version = "TLSv1.2_2021" # Recommended minimum TLS version
    } : {
    cloudfront_default_certificate = true # Use default *.cloudfront.net cert if no aliases/custom cert
  }

  # WAF configuration block only if enabled and ARN provided
  web_acl_id = var.enable_waf && var.waf_web_acl_arn != null ? var.waf_web_acl_arn : null

}

# --- Origin Access Control for S3 ---
# Grants CloudFront access to the S3 bucket
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for ${var.project_name} ${var.environment} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # Recommended: CloudFront always signs requests
  signing_protocol                  = "sigv4"  # Required for S3
}

# --- CloudFront Distribution ---
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for ${var.project_name} ${var.environment}"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.domain_aliases # Associate custom domain names

  # --- Origins ---
  origin {
    # S3 Origin for Static Assets
    domain_name              = var.s3_static_assets_bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id # Use OAC
  }

  origin {
    # ALB Origin for API / Dynamic Content
    domain_name = var.alb_dns_name
    origin_id   = local.alb_origin_id
    custom_origin_config {
      http_port                = 80  # ALB listening port (traffic CF -> ALB)
      https_port               = 443 # ALB listening port (traffic CF -> ALB)
      origin_protocol_policy   = "https-only" # Enforce HTTPS between CloudFront and ALB
      origin_ssl_protocols     = ["TLSv1.2"] # Minimum TLS version to connect to origin
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }
    # Optional: Add custom headers if needed
    # custom_header {
    #   name  = "X-Custom-Header"
    #   value = "my-value"
    # }
  }

  # --- Default Cache Behavior (targets S3 origin) ---
  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    allowed_methods        = ["GET", "HEAD", "OPTIONS"] # Read-only methods for static assets
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https" # Redirect HTTP viewers to HTTPS

    cache_policy_id = var.static_assets_cache_policy_id # Use Managed-CachingOptimized or custom policy
    # origin_request_policy_id = Managed-CORS-S3Origin ID # If CORS needed for S3
    compress = true # Enable automatic compression (Gzip, Brotli)
  }

  # --- Ordered Cache Behavior for API (targets ALB origin) ---
  ordered_cache_behavior {
    path_pattern           = var.api_path_pattern # e.g., "/api/*"
    target_origin_id       = local.alb_origin_id
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"] # Allow all methods for API
    cached_methods         = ["GET", "HEAD"] # Typically only GET/HEAD are cached
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = var.api_cache_policy_id          # Use Managed-CachingDisabled or custom policy
    origin_request_policy_id = var.api_origin_request_policy_id # Use Managed-AllViewer (forward headers/cookies/QS) or custom policy
    compress = true
  }

  # --- Error Responses (Optional: Custom error pages) ---
  # custom_error_response {
  #   error_caching_min_ttl = 10
  #   error_code            = 404
  #   response_code         = 200
  #   response_page_path    = "/errors/404.html"
  # }
  # custom_error_response {
  #   error_caching_min_ttl = 10
  #   error_code            = 403
  #   response_code         = 200
  #   response_page_path    = "/errors/403.html"
  # }

  # --- Geo Restrictions (Optional) ---
  restrictions {
    geo_restriction {
      restriction_type = "whitelist" # or blacklist
      locations        = [] # Example list of allowed countries
    }
  }

  # --- Viewer Certificate ---
  viewer_certificate {
    # Use custom cert if aliases provided, otherwise default CloudFront cert
    acm_certificate_arn      = local.viewer_certificate_config.acm_certificate_arn
    ssl_support_method       = local.viewer_certificate_config.ssl_support_method
    minimum_protocol_version = local.viewer_certificate_config.minimum_protocol_version
    cloudfront_default_certificate = local.viewer_certificate_config.cloudfront_default_certificate
  }

  # --- Logging ---
  dynamic "logging_config" {
    for_each = local.logging_config != null ? [local.logging_config] : []
    content {
      include_cookies = logging_config.value.include_cookies
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
    }
  }

  # --- WAF Association ---
  web_acl_id = local.web_acl_id # Associate the WAFv2 Web ACL ARN (must be us-east-1)

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-cdn"
  })

  # Explicit dependency can help if bucket policy relies on distribution ARN
  depends_on = [aws_cloudfront_origin_access_control.s3_oac]
}

# --- S3 Bucket Policy Update Needed ---
# NOTE: You need to update the S3 static assets bucket policy to grant access
# to the CloudFront distribution service principal using the OAC.
# This is typically done in the S3 module (`modules/05_s3/`) by adding a policy resource
# that references the CloudFront distribution ARN or OAC ID.
# Example policy statement to add to the S3 bucket policy:
/*
data "aws_iam_policy_document" "s3_cloudfront_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3.static_assets_bucket_arn}/*"] # Reference S3 bucket ARN

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.edge.cloudfront_distribution_arn] # Reference CloudFront ARN from this module's output
    }
  }
}

resource "aws_s3_bucket_policy" "static_assets_policy" {
  # Defined in S3 module or root
  bucket = module.s3.static_assets_bucket_id
  policy = data.aws_iam_policy_document.s3_cloudfront_access.json
}
*/