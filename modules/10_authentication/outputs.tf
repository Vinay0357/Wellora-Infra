# -----------------------------------------------------------------------------
# Outputs from the authentication module
# -----------------------------------------------------------------------------

output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_arn" {
  description = "The ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.arn
}

output "user_pool_endpoint" {
  description = "The endpoint for the Cognito User Pool (e.g., for SDKs)"
  value       = aws_cognito_user_pool.user_pool.endpoint
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.app_client.id
}

output "user_pool_client_secret" {
  description = "The secret for the Cognito User Pool Client (if generated)"
  value       = aws_cognito_user_pool_client.app_client.client_secret
  sensitive   = true
}

output "user_pool_domain" {
  description = "The domain prefix for the Cognito User Pool domain (if created)"
  value       = length(aws_cognito_user_pool_domain.domain) > 0 ? aws_cognito_user_pool_domain.domain[0].domain : null
}

output "user_pool_domain_cloudfront_distribution_domain_name" {
  description = "The CloudFront distribution domain name corresponding to the User Pool domain (if created)"
  value       = length(aws_cognito_user_pool_domain.domain) > 0 ? aws_cognito_user_pool_domain.domain[0].cloudfront_distribution_arn : null # Note: this is the CF ARN, domain is just prefix.auth.region.amazoncognito.com
  # Actual domain is constructed like: https://{domain_prefix}.auth.{region}.amazoncognito.com
}

output "user_pool_domain_full_url" {
  description = "The full URL for the Cognito User Pool domain (if created)"
  value       = length(aws_cognito_user_pool_domain.domain) > 0 ? "https://${aws_cognito_user_pool_domain.domain[0].domain}.auth.${data.aws_region.current.name}.amazoncognito.com" : null
}

# Data source needed for the output above
data "aws_region" "current" {}
