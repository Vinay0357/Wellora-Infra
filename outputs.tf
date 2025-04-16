output "vpc_id_output" {
  description = "VPC ID from networking module"
  value       = module.networking.vpc_id
}

output "private_app_subnets_output" {
  description = "Private App Subnet IDs from networking module"
  value       = module.networking.private_app_subnet_ids
}

output "app_sg_id_output" {
  description = "App Tier Security Group ID"
  value       = module.security_groups.app_security_group_id
}

output "db_sg_id_output" {
  description = "DB Tier Security Group ID"
  value       = module.security_groups.db_security_group_id
}

output "alb_sg_id_output" {
  description = "ALB Security Group ID"
  value       = module.security_groups.alb_security_group_id
}

output "vpc_endpoint_sg_id_output" {
  description = "VPC Endpoint Security Group ID"
  value       = module.vpc_endpoints.vpc_endpoint_security_group_id
}

output "app_task_role_arn_output" {
  description = "ARN of the main application task/pod role"
  value       = module.iam.app_task_role_arn
}

output "eks_node_role_name_output" {
  description = "Name of the EKS node role (useful for EKS node group config)"
  value       = module.iam.eks_node_role_name
}

# (used in IAM module variables)
# output "raw_audio_bucket_arn_output" {
#   description = "ARN of the raw audio bucket"
#   value = module.s3.raw_audio_bucket_arn
# }

# output "transcripts_bucket_arn_output" {
#   description = "ARN of the transcripts bucket"
#   value = module.s3.transcripts_bucket_arn
# }

# output "static_assets_bucket_arn_output" {
#   description = "ARN of the static assets bucket"
#   value = module.s3.static_assets_bucket_arn
# }

# (used in IAM module variables)
# output "app_data_table_arn_output" {
#   description = "ARN of the main DynamoDB table"
#   value = module.persistence.dynamodb_table_arns["WelloraAppTable"] # Access specific table ARN
# }
# output "rds_endpoint_output" {
#   description = "RDS database endpoint"
#   value = module.persistence.rds_instance_endpoint
# }
# output "redis_endpoint_output" {
#  description = "Redis primary endpoint"
#  value = module.persistence.elasticache_redis_primary_endpoint_address
# }

# (used in IAM module config for IRSA, or for kubectl setup)
output "eks_cluster_endpoint_output" {
  description = "EKS Cluster API Endpoint"
  value       = module.compute.eks_cluster_endpoint
}

output "eks_oidc_provider_arn_output" {
  description = "EKS OIDC Provider ARN (for IAM module)"
  value       = module.compute.eks_oidc_provider_arn
}

# The OIDC URL output might need stripping https:// before passing to IAM module
output "eks_oidc_provider_url_output" {
 description = "EKS OIDC Provider URL (for IAM module)"
 value       = module.compute.eks_oidc_provider_url
}

output "app_repo_urls_output" {
 description = "URLs for application ECR repositories"
 value       = module.compute.ecr_repository_urls
}

output "alb_dns_output" {
  description = "Public DNS name for the Application Load Balancer"
  value       = module.load_balancing.alb_dns_name
}

output "cdn_domain_name_output" {
  description = "CloudFront distribution domain name"
  value       = module.edge.cloudfront_distribution_domain_name
}

output "cognito_user_pool_id_output" {
  description = "Cognito User Pool ID"
  value       = module.authentication.user_pool_id
}

output "cognito_user_pool_client_id_output" {
  description = "Cognito User Pool Client ID (for frontend app config)"
  value       = module.authentication.user_pool_client_id
}

output "cognito_user_pool_endpoint_output" {
  description = "Cognito User Pool Endpoint (for SDKs)"
  value       = module.authentication.user_pool_endpoint
}

output "ses_dkim_tokens_output" {
  description = "DKIM tokens for SES domain (Requires manual DNS setup)"
  value       = module.messaging.ses_dkim_tokens
}

output "app_events_sns_topic_arn_output" {
  description = "ARN for the AppEvents SNS Topic (use in IAM policies)"
  value       = module.messaging.sns_topic_arns["AppEvents"] # Access specific topic ARN
}

output "healthlake_endpoint_output" {
  description = "HealthLake FHIR Datastore Endpoint"
  value       = module.ai_services.healthlake_datastore_endpoint
}

output "guardduty_detector_id_output" {
  description = "GuardDuty Detector ID"
  value       = module.security_compliance.guardduty_detector_id
}

output "vpn_endpoint_id_output" {
  description = "Client VPN Endpoint ID"
  value       = module.admin_access.client_vpn_endpoint_id
}
output "vpn_client_cidr_output" {
  description = "CIDR block for VPN clients (Use this in other Security Group rules)"
  value       = module.admin_access.client_cidr_block
}