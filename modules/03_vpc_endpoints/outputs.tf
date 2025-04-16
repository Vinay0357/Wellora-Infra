# -----------------------------------------------------------------------------
# Outputs from the vpc_endpoints module
# -----------------------------------------------------------------------------

output "vpc_endpoint_security_group_id" {
  description = "The ID of the security group created for Interface Endpoints"
  value       = length(aws_security_group.vpc_endpoint_sg) > 0 ? aws_security_group.vpc_endpoint_sg[0].id : null
}

output "s3_gateway_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint"
  value       = length(aws_vpc_endpoint.s3_gateway) > 0 ? aws_vpc_endpoint.s3_gateway[0].id : null
}

output "dynamodb_gateway_endpoint_id" {
  description = "The ID of the DynamoDB Gateway VPC Endpoint"
  value       = length(aws_vpc_endpoint.dynamodb_gateway) > 0 ? aws_vpc_endpoint.dynamodb_gateway[0].id : null
}

# Add outputs for Interface endpoint IDs if needed, e.g.:
# output "transcribe_interface_endpoint_id" {
#   description = "The ID of the Transcribe Interface VPC Endpoint"
#   value       = length(aws_vpc_endpoint.transcribe) > 0 ? aws_vpc_endpoint.transcribe[0].id : null
# }
# output "bedrock_interface_endpoint_id" { ... }
# output "healthlake_interface_endpoint_id" { ... }
# output "ecr_api_interface_endpoint_id" { ... }
# output "ecr_dkr_interface_endpoint_id" { ... }
# output "logs_interface_endpoint_id" { ... }
# output "ssm_interface_endpoint_id" { ... }
# output "ssmmessages_interface_endpoint_id" { ... }
# output "ec2messages_interface_endpoint_id" { ... }

output "interface_endpoint_ids" {
  description = "Map of created Interface Endpoint IDs"
  value = {
    transcribe   = length(aws_vpc_endpoint.transcribe) > 0 ? aws_vpc_endpoint.transcribe[0].id : null
    bedrock      = length(aws_vpc_endpoint.bedrock) > 0 ? aws_vpc_endpoint.bedrock[0].id : null
    healthlake   = length(aws_vpc_endpoint.healthlake) > 0 ? aws_vpc_endpoint.healthlake[0].id : null
    ecr_api      = length(aws_vpc_endpoint.ecr_api) > 0 ? aws_vpc_endpoint.ecr_api[0].id : null
    ecr_dkr      = length(aws_vpc_endpoint.ecr_dkr) > 0 ? aws_vpc_endpoint.ecr_dkr[0].id : null
    logs         = length(aws_vpc_endpoint.logs) > 0 ? aws_vpc_endpoint.logs[0].id : null
    ssm          = length(aws_vpc_endpoint.ssm) > 0 ? aws_vpc_endpoint.ssm[0].id : null
    ssmmessages  = length(aws_vpc_endpoint.ssmmessages) > 0 ? aws_vpc_endpoint.ssmmessages[0].id : null
    ec2messages  = length(aws_vpc_endpoint.ec2messages) > 0 ? aws_vpc_endpoint.ec2messages[0].id : null
  }
}