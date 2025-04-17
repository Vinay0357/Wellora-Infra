# -----------------------------------------------------------------------------
# VPC Endpoints Module - Refactored with for_each
# -----------------------------------------------------------------------------

locals {
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "vpc_endpoints"
    }
  )

  endpoint_service_names = {
    transcribe    = "com.amazonaws.${var.aws_region}.transcribe"
    bedrock       = "com.amazonaws.${var.aws_region}.bedrock-runtime"
    healthlake    = "com.amazonaws.${var.aws_region}.healthlake"
    ecr_api       = "com.amazonaws.${var.aws_region}.ecr.api"
    ecr_dkr       = "com.amazonaws.${var.aws_region}.ecr.dkr"
    s3_interface  = "com.amazonaws.${var.aws_region}.s3"
    logs          = "com.amazonaws.${var.aws_region}.logs"
    ssm           = "com.amazonaws.${var.aws_region}.ssm"
    ssmmessages   = "com.amazonaws.${var.aws_region}.ssmmessages"
    ec2messages   = "com.amazonaws.${var.aws_region}.ec2messages"
  }

  enabled_interface_endpoints = {
    for key, value in var.interface_endpoints_enabled :
    key => value if value
  }
}

# --- Security Group for Interface Endpoints ---
resource "aws_security_group" "vpc_endpoint_sg" {
  for_each = length(local.enabled_interface_endpoints) > 0 ? { create = true } : {}

  name        = "${var.project_name}-${var.environment}-vpc-endpoint-sg"
  description = "SG for Interface VPC Endpoints - Allows HTTPS from App Tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from App Tier SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.app_tier_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-endpoint-sg"
  })
}

# --- Gateway Endpoints ---
resource "aws_vpc_endpoint" "gateway_endpoints" {
  for_each = {
    for k, v in {
      s3        = var.create_s3_gateway_endpoint
      dynamodb  = var.create_dynamodb_gateway_endpoint
    } : k => v if v
  }

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}-gw-endpoint"
  })
}

# --- Interface Endpoints ---
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = local.enabled_interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = local.endpoint_service_names[each.key]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [for sg in aws_security_group.vpc_endpoint_sg : sg.value.id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-${each.key}-if-endpoint"
  })
}