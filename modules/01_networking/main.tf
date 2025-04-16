# -----------------------------------------------------------------------------
# Networking Module - Main Configuration
# Creates VPC, Subnets, IGW, NAT Gateways, Route Tables
# -----------------------------------------------------------------------------

# --- Data Source for Availability Zones ---
# Use specific AZs passed in variable OR get available ones dynamically
data "aws_availability_zones" "available" {
  # If var.availability_zones is empty, get available ones. Otherwise, use the provided list.
  # This assumes the provided list contains valid AZ names for the region.
  # Using `filter` might be safer if passing names:
  # filter {
  #   name   = "zone-name"
  #   values = var.availability_zones
  # }
  # For simplicity here, relying on either the passed list or fetching available ones.
  # If `var.availability_zones` is populated, ensure its length matches subnet counts.
  count = length(var.availability_zones) == 0 ? 1 : 0
  state = "available"
}

locals {
  # Determine the AZs to use: either the provided list or the dynamically fetched ones
  region     = var.aws_region
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available[0].names

  # Ensure we only try to create resources for the minimum number of AZs defined across subnet lists
  num_azs = min(length(local.azs), length(var.public_subnet_cidrs), length(var.private_app_subnet_cidrs), length(var.private_db_subnet_cidrs))

  # Construct common tags by merging defaults and module-specific tags
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

# Public Subnets
resource "aws_subnet" "public" {
  count             = local.num_azs
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]
  # Only map public IP if NOT using NAT Gateway primarily (ALBs/Bastions might still need it)
  map_public_ip_on_launch = true # Keep true for simplicity, NAT GW needs public subnet anyway

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${substr(local.azs[count.index], -1, 1)}" # e.g., wellora-prod-public-subnet-a
    Tier = "Public"
  })
}

# Private App Subnets
resource "aws_subnet" "private_app" {
  count             = local.num_azs
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-app-private-subnet-${substr(local.azs[count.index], -1, 1)}"
    Tier = "PrivateApp"
  })
}

# Private DB Subnets
resource "aws_subnet" "private_db" {
  count             = local.num_azs
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-db-private-subnet-${substr(local.azs[count.index], -1, 1)}"
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

# --- NAT Gateways & Elastic IPs (Conditional) ---
resource "aws_eip" "nat_eip" {
  # Create one EIP per AZ if enable_nat_gateway is true and single_nat_gateway is false
  # Create only one EIP if enable_nat_gateway is true and single_nat_gateway is true
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.num_azs) : 0
  domain   = "vpc" # Changed from `vpc = true` for newer AWS provider versions
  depends_on = [aws_internet_gateway.gw] # Ensure IGW exists before allocating EIP in VPC

  tags = merge(local.module_tags, {
    # Tagging the single EIP or each AZ-specific EIP
    Name = var.single_nat_gateway ? "${var.project_name}-${var.environment}-nat-eip-single" : "${var.project_name}-${var.environment}-nat-eip-${substr(local.azs[count.index], -1, 1)}"
  })
}

resource "aws_nat_gateway" "nat_gw" {
  # Create one NAT GW per AZ if enable_nat_gateway is true and single_nat_gateway is false (place in corresponding public subnet)
  # Create only one NAT GW if enable_nat_gateway is true and single_nat_gateway is true (place in the first public subnet)
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : local.num_azs) : 0
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Places NAT in the corresponding public subnet

  tags = merge(local.module_tags, {
    Name = var.single_nat_gateway ? "${var.project_name}-${var.environment}-nat-gw-single" : "${var.project_name}-${var.environment}-nat-gw-${substr(local.azs[count.index], -1, 1)}"
  })
}


# --- Route Tables ---

# Public Route Table (Routes to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  # Add IPv6 route later if needed

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-public-rtb"
    Tier = "Public"
  })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = local.num_azs
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (One per AZ, routing to NAT Gateway if enabled)
resource "aws_route_table" "private" {
  count  = local.num_azs # One route table per AZ for private subnets
  vpc_id = aws_vpc.main.id

  # Add route to NAT Gateway only if NAT Gateway is enabled
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : [] # Create route block if NAT is enabled
    content {
      cidr_block = "0.0.0.0/0"
      # Route to the single NAT GW if single_nat_gateway is true, otherwise route to the NAT GW in the same AZ
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.nat_gw[0].id : aws_nat_gateway.nat_gw[count.index].id
    }
  }
  # Add routes for VPC Endpoints (like S3 Gateway) here or manage them in the endpoints module

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-private-rtb-${substr(local.azs[count.index], -1, 1)}"
    Tier = "Private"
  })
}

# Associate Private App Subnets with corresponding AZ's Private Route Table
resource "aws_route_table_association" "private_app" {
  count          = local.num_azs
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Associate Private DB Subnets with corresponding AZ's Private Route Table
resource "aws_route_table_association" "private_db" {
  count          = local.num_azs
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}