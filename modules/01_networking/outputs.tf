# -----------------------------------------------------------------------------
# Outputs from the networking module
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The primary CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "availability_zones_used" {
  description = "List of Availability Zones resources were created in"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "List of IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "List of IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables (one per AZ)"
  value       = aws_route_table.private[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.gw.id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways created (if enabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.nat_gw[*].id : []
}

output "nat_gateway_public_ips" {
  description = "List of Public IPs assigned to the NAT Gateways (if enabled)"
  value       = var.enable_nat_gateway ? aws_eip.nat_eip[*].public_ip : []
}