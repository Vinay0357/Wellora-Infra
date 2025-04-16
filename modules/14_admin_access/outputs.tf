# -----------------------------------------------------------------------------
# Outputs from the admin_access module
# -----------------------------------------------------------------------------

output "client_vpn_endpoint_id" {
  description = "The ID of the AWS Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
}

output "client_vpn_endpoint_dns_name" {
  description = "The DNS name to be used by clients when establishing their VPN session"
  value       = aws_ec2_client_vpn_endpoint.vpn_endpoint.dns_name
}

output "client_cidr_block" {
  description = "The CIDR block assigned to VPN clients. Needed for Security Group rules."
  value       = var.client_cidr_block
}

output "connection_log_group_name" {
  description = "Name of the CloudWatch Log Group for connection logs"
  value       = length(aws_cloudwatch_log_group.vpn_log_group) > 0 ? aws_cloudwatch_log_group.vpn_log_group[0].name : null
}
