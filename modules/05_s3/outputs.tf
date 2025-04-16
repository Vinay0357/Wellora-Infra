# -----------------------------------------------------------------------------
# Outputs from the s3 module
# -----------------------------------------------------------------------------

output "static_assets_bucket_id" {
  description = "The name (ID) of the static assets S3 bucket"
  value       = aws_s3_bucket.static_assets.id
}

output "static_assets_bucket_arn" {
  description = "The ARN of the static assets S3 bucket"
  value       = aws_s3_bucket.static_assets.arn
}

output "static_assets_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name for the static assets bucket"
  value       = aws_s3_bucket.static_assets.bucket_regional_domain_name
}

output "raw_audio_bucket_id" {
  description = "The name (ID) of the raw audio S3 bucket"
  value       = aws_s3_bucket.raw_audio.id
}

output "raw_audio_bucket_arn" {
  description = "The ARN of the raw audio S3 bucket"
  value       = aws_s3_bucket.raw_audio.arn
}

output "transcripts_bucket_id" {
  description = "The name (ID) of the transcripts S3 bucket"
  value       = aws_s3_bucket.transcripts.id
}

output "transcripts_bucket_arn" {
  description = "The ARN of the transcripts S3 bucket"
  value       = aws_s3_bucket.transcripts.arn
}

output "access_log_bucket_id" {
  description = "The name (ID) of the S3 access log bucket (if created)"
  value       = length(aws_s3_bucket.log_bucket) > 0 ? aws_s3_bucket.log_bucket[0].id : null
}

output "access_log_bucket_arn" {
  description = "The ARN of the S3 access log bucket (if created)"
  value       = length(aws_s3_bucket.log_bucket) > 0 ? aws_s3_bucket.log_bucket[0].arn : null
}