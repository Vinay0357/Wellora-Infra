output "vpc_endpoint_security_group_id" {
  description = "The ID of the security group created for Interface Endpoints"
  value       = length(aws_security_group.vpc_endpoint_sg) > 0 ? values(aws_security_group.vpc_endpoint_sg)[0].id : null
}

output "s3_gateway_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint"
  value       = contains(keys(aws_vpc_endpoint.gateway_endpoints), "s3") ? aws_vpc_endpoint.gateway_endpoints["s3"].id : null
}

output "dynamodb_gateway_endpoint_id" {
  description = "The ID of the DynamoDB Gateway VPC Endpoint"
  value       = contains(keys(aws_vpc_endpoint.gateway_endpoints), "dynamodb") ? aws_vpc_endpoint.gateway_endpoints["dynamodb"].id : null
}

output "interface_endpoint_ids" {
  description = "Map of created Interface Endpoint IDs"
  value       = {
    for key, ep in aws_vpc_endpoint.interface_endpoints :
    key => ep.id
  }
}
