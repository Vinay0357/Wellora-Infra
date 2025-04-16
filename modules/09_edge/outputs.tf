# -----------------------------------------------------------------------------
# Outputs from the edge module
# -----------------------------------------------------------------------------

output "cloudfront_distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the distribution (e.g., d111111abcdef8.cloudfront.net)"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to."
  value       = aws_cloudfront_distribution.cdn.hosted_zone_id
}

output "s3_origin_access_control_id" {
  description = "The ID of the Origin Access Control for S3"
  value       = aws_cloudfront_origin_access_control.s3_oac.id
}