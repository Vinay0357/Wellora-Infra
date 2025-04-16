# -----------------------------------------------------------------------------
# VPC Endpoints Module - Main Configuration
# Creates Gateway and Interface Endpoints for various AWS services
# -----------------------------------------------------------------------------

locals {
  # Construct common tags by merging defaults and module-specific tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "vpc_endpoints"
    }
  )

  # Interface endpoint service names often depend on the region
  # Note: Some service names might differ slightly or new ones might emerge. Verify in AWS docs if needed.
  endpoint_service_names = {
    transcribe    = "com.amazonaws.${var.aws_region}.transcribe"
    bedrock       = "com.amazonaws.${var.aws_region}.bedrock-runtime" # Or bedrock-agent-runtime, etc. Check specific need.
    healthlake    = "com.amazonaws.${var.aws_region}.healthlake"
    ecr_api       = "com.amazonaws.${var.aws_region}.ecr.api"
    ecr_dkr       = "com.amazonaws.${var.aws_region}.ecr.dkr"
    s3_interface  = "com.amazonaws.${var.aws_region}.s3" # Interface endpoint for S3 (less common than Gateway)
    logs          = "com.amazonaws.${var.aws_region}.logs"
    ssm           = "com.amazonaws.${var.aws_region}.ssm"
    ssmmessages   = "com.amazonaws.${var.aws_region}.ssmmessages"
    ec2messages   = "com.amazonaws.${var.aws_region}.ec2messages"
  }
}

# --- Security Group for Interface Endpoints ---
# Allows traffic from the App Tier SG on HTTPS
resource "aws_security_group" "vpc_endpoint_sg" {
  # Only create if at least one interface endpoint is being created
  count = anytrue([
    var.create_transcribe_interface_endpoint ||
    var.create_bedrock_interface_endpoint ||
    var.create_healthlake_interface_endpoint ||
    var.create_ecr_interface_endpoints ||
    var.create_logs_interface_endpoint ||
    var.create_ssm_interface_endpoints
    ]) ? 1 : 0

  name        = "${var.project_name}-${var.environment}-vpc-endpoint-sg"
  description = "SG for Interface VPC Endpoints - Allows HTTPS from App Tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from App Tier SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.app_tier_security_group_id] # Allow from App Tier
  }

  # Egress typically not needed as endpoints initiate connections outbound to the service
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound necessary for endpoint operation
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-endpoint-sg"
  })
}

# --- Gateway Endpoints ---

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_gateway" {
  count        = var.create_s3_gateway_endpoint ? 1 : 0
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.private_route_table_ids # Associate with private route tables

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-s3-gw-endpoint"
  })
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb_gateway" {
  count        = var.create_dynamodb_gateway_endpoint ? 1 : 0
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = var.private_route_table_ids # Associate with private route tables

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-dynamodb-gw-endpoint"
  })
}


# --- Interface Endpoints ---
# Note: Interface endpoints incur hourly costs and costs per GB processed.

# Transcribe Interface Endpoint
resource "aws_vpc_endpoint" "transcribe" {
  count                     = var.create_transcribe_interface_endpoint ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.transcribe
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true # Allows using standard DNS names (e.g., transcribe.region.amazonaws.com)
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-transcribe-if-endpoint"
  })
}

# Bedrock Interface Endpoint
resource "aws_vpc_endpoint" "bedrock" {
  count                     = var.create_bedrock_interface_endpoint ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.bedrock
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-bedrock-if-endpoint"
  })
}

# HealthLake Interface Endpoint
resource "aws_vpc_endpoint" "healthlake" {
  count                     = var.create_healthlake_interface_endpoint ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.healthlake
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-healthlake-if-endpoint"
  })
}

# ECR API Interface Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  count                     = var.create_ecr_interface_endpoints ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.ecr_api
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-ecr-api-if-endpoint"
  })
}

# ECR DKR Interface Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  count                     = var.create_ecr_interface_endpoints ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.ecr_dkr
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-ecr-dkr-if-endpoint"
  })
}

# CloudWatch Logs Interface Endpoint
resource "aws_vpc_endpoint" "logs" {
  count                     = var.create_logs_interface_endpoint ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.logs
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-logs-if-endpoint"
  })
}

# SSM Interface Endpoint
resource "aws_vpc_endpoint" "ssm" {
  count                     = var.create_ssm_interface_endpoints ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.ssm
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-ssm-if-endpoint"
  })
}

# SSMMessages Interface Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  count                     = var.create_ssm_interface_endpoints ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.ssmmessages
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-ssmmessages-if-endpoint"
  })
}

# EC2Messages Interface Endpoint
resource "aws_vpc_endpoint" "ec2messages" {
  count                     = var.create_ssm_interface_endpoints ? 1 : 0
  vpc_id                    = var.vpc_id
  service_name              = local.endpoint_service_names.ec2messages
  vpc_endpoint_type         = "Interface"
  private_dns_enabled       = true
  subnet_ids                = var.private_subnet_ids
  security_group_ids        = [aws_security_group.vpc_endpoint_sg[0].id]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-ec2messages-if-endpoint"
  })
}
