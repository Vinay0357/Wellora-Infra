# ----------------------------------------------------------------------------- 
# Networking Module - Main Configuration
# -----------------------------------------------------------------------------

# --- Data Source for Availability Zones ---
data "aws_availability_zones" "available" {
  state = "available"
}

# --- Locals ---
locals {
  region = var.aws_region

  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, var.number_of_azs_to_use)

  num_azs = min(
    length(local.azs),
    length(var.public_subnet_cidrs),
    length(var.private_app_subnet_cidrs),
    length(var.private_db_subnet_cidrs)
  )

  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "networking"
    }
  )
}

# --- VPC ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  instance_tenancy     = "default"

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# --- Subnets ---
resource "aws_subnet" "public" {
  for_each = {
    for idx, az in local.azs : az => {
      cidr = var.public_subnet_cidrs[idx]
    }
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${substr(each.key, -1, 1)}"
    Tier = "Public"
  })
}

resource "aws_subnet" "private_app" {
  for_each = {
    for idx, az in local.azs : az => {
      cidr = var.private_app_subnet_cidrs[idx]
    }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-app-private-subnet-${substr(each.key, -1, 1)}"
    Tier = "PrivateApp"
  })
}

resource "aws_subnet" "private_db" {
  for_each = {
    for idx, az in local.azs : az => {
      cidr = var.private_db_subnet_cidrs[idx]
    }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-db-private-subnet-${substr(each.key, -1, 1)}"
    Tier = "PrivateDB"
  })
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# --- NAT Gateways & EIPs ---
resource "aws_eip" "nat_eip" {
  for_each = var.enable_nat_gateway ? (
  var.single_nat_gateway ? { "single" = "single" } : { for az in local.azs : az => az }
) : {}

  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]

  tags = merge(local.module_tags, {
    Name = var.single_nat_gateway ? "${var.project_name}-${var.environment}-nat-eip-single" : "${var.project_name}-${var.environment}-nat-eip-${substr(each.key, -1, 1)}"
  })
}

resource "aws_nat_gateway" "nat_gw" {
  for_each = aws_eip.nat_eip

  allocation_id = each.value.id
  subnet_id     = var.single_nat_gateway ? aws_subnet.public[local.azs[0]].id : aws_subnet.public[each.key].id

  tags = merge(local.module_tags, {
    Name = var.single_nat_gateway ? "${var.project_name}-${var.environment}-nat-gw-single" : "${var.project_name}-${var.environment}-nat-gw-${substr(each.key, -1, 1)}"
  })
}


# --- Route Tables ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-public-rtb"
    Tier = "Public"
  })
}

resource "aws_route_table" "private" {
  for_each = toset(local.azs)

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.nat_gw["single"].id : aws_nat_gateway.nat_gw[each.key].id
    }
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-private-rtb-${substr(each.key, -1, 1)}"
    Tier = "Private"
  })
}

# --- Route Table Associations ---
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}