# -----------------------------------------------------------------------------
# Admin Access Module - Main Configuration (AWS Client VPN Endpoint)
# -----------------------------------------------------------------------------

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "admin_access"
    }
  )
}

# --- CloudWatch Log Group & Stream for Connection Logging ---
resource "aws_cloudwatch_log_group" "vpn_log_group" {
  count = var.enable_connection_logging ? 1 : 0

  name              = "/aws/client-vpn/${var.project_name}-${var.environment}"
  retention_in_days = 90 # Example retention period
  tags              = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-client-vpn-lg" })
}

resource "aws_cloudwatch_log_stream" "vpn_log_stream" {
  count = var.enable_connection_logging ? 1 : 0

  name           = "${var.project_name}-${var.environment}-connections"
  log_group_name = aws_cloudwatch_log_group.vpn_log_group[0].name
}

# --- AWS Client VPN Endpoint ---
resource "aws_ec2_client_vpn_endpoint" "vpn_endpoint" {
  description            = "${var.project_name} ${var.environment} Client VPN Endpoint"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = var.split_tunnel_enabled
  dns_servers            = var.dns_servers

  # Authentication Options
  authentication_options {
    type                        = var.authentication_type
    root_certificate_chain_arn  = var.authentication_type == "certificate-authentication" ? var.client_certificate_arn : null
    # active_directory_id = var.authentication_type == "directory-service-authentication" ? var.directory_id : null
    # saml_provider_arn = var.authentication_type == "federated-authentication" ? var.saml_provider_arn : null
  }

  # Connection Logging
  connection_log_options {
    enabled               = var.enable_connection_logging
    cloudwatch_log_group  = var.enable_connection_logging ? aws_cloudwatch_log_group.vpn_log_group[0].name : null
    cloudwatch_log_stream = var.enable_connection_logging ? aws_cloudwatch_log_stream.vpn_log_stream[0].name : null
  }

  # Security Group association - applied to the ENIs created in associated subnets
  security_group_ids = var.vpn_endpoint_security_group_ids

  # Use defaults for transport protocol (UDP) and port (443) unless needed otherwise
  # transport_protocol = "udp"
  # vpn_port = 443

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-client-vpn"
  })
}

# --- Network Associations ---
# Associate the VPN endpoint with target subnets (at least two in different AZs for HA)
resource "aws_ec2_client_vpn_network_association" "subnet_assoc" {
  # Create an association for each subnet provided
  for_each = toset(var.vpn_target_subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  subnet_id              = each.value

  # Security groups are applied at the endpoint level now, not per association
  # security_groups = var.vpn_endpoint_security_group_ids
}

# --- Authorization Rules ---
# Grant access from VPN clients to target networks
resource "aws_ec2_client_vpn_authorization_rule" "vpc_access" {
  count = var.authorize_all_users_to_vpc ? 1 : 0

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  target_network_cidr    = var.vpc_cidr_for_authorization # Authorize access to the whole VPC CIDR
  authorize_all_groups   = true                           # Allow all authenticated users (can set to false and use group names for AD/Federated)
  description            = "Allow VPN users access to VPC ${var.vpc_cidr_for_authorization}"
  depends_on = [
     aws_ec2_client_vpn_network_association.subnet_assoc # Ensure associations are done first
  ]
}

# Add more granular authorization rules if needed (e.g., specific subnets, on-prem networks)
# resource "aws_ec2_client_vpn_authorization_rule" "specific_subnet_access" { ... }


# --- Routes ---
# Routes are often automatically created for associated subnets, but explicit definition can be useful
# If split_tunnel is false, you'll need a route for 0.0.0.0/0 pointing to a subnet associated with a NAT Gateway
resource "aws_ec2_client_vpn_route" "vpc_route" {
  # Create a route for each associated subnet to ensure traffic stays within VPC
  for_each = toset(var.vpn_target_subnet_ids)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
  destination_cidr_block = var.vpc_cidr_for_authorization # Route for the entire VPC
  target_vpc_subnet_id   = each.value # Route via the associated subnet ENI

  description = "Route for VPC CIDR via subnet ${each.value}"

  depends_on = [
    aws_ec2_client_vpn_network_association.subnet_assoc # Ensure associations are done first
  ]
}

# Example route for Internet access if split tunnel disabled
# resource "aws_ec2_client_vpn_route" "internet_route" {
#   count = !var.split_tunnel_enabled ? 1 : 0
#
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn_endpoint.id
#   destination_cidr_block = "0.0.0.0/0"
#   target_vpc_subnet_id   = var.vpn_target_subnet_ids[0] # Route via first associated subnet (ensure it has NAT route)
#   description            = "Route for Internet access"
#
#   depends_on = [ aws_ec2_client_vpn_network_association.subnet_assoc ]
# }
