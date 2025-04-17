# -----------------------------------------------------------------------------
# Security Groups Module - Main Configuration
# Creates SGs for ALB, App Tier, DB Tier
# -----------------------------------------------------------------------------

locals {
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "security_groups"
    }
  )
  region            = var.aws_region
  anywhere_ipv4     = ["0.0.0.0/0"]
  anywhere_ipv6     = ["::/0"]
  no_traffic        = []
}

# --- ALB Security Group ---
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "SG for the Application Load Balancer - allows web traffic ingress"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_ports
    content {
      description      = "Allow port ${ingress.value} from Internet"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = var.allow_all_internet_ingress_for_alb ? local.anywhere_ipv4 : var.admin_access_cidrs
      ipv6_cidr_blocks = var.allow_all_internet_ingress_for_alb ? local.anywhere_ipv6 : local.no_traffic
    }
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = local.anywhere_ipv4
    ipv6_cidr_blocks = local.anywhere_ipv6
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Tier = "Public/Edge"
  })
}

# --- Application Tier Security Group ---
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "SG for Application Tier (EKS, ECS, EC2)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from Admin CIDRs"
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = length(var.admin_access_cidrs) > 0 ? var.admin_access_cidrs : local.no_traffic
  }

  ingress {
    description = "Allow internal App Tier communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = local.anywhere_ipv4
    ipv6_cidr_blocks = local.anywhere_ipv6
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
    Tier = "Application"
  })
}

# --- Database Tier Security Group ---
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "SG for Database Tier (RDS, ElastiCache)"
  vpc_id      = var.vpc_id

  egress {
    description = "Restrict egress by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.no_traffic
  }

  tags = merge(local.module_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
    Tier = "Database"
  })
}

# --- Inter-Security Group Rules ---

# ALB -> App Tier on App Port
resource "aws_security_group_rule" "allow_alb_to_app" {
  type                     = "ingress"
  description              = "Allow traffic from ALB to App on port ${var.app_port}"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

# App Tier -> DB Tier on DB Port
resource "aws_security_group_rule" "allow_app_to_db" {
  type                     = "ingress"
  description              = "Allow traffic from App to DB on port ${var.db_port}"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}

# ALB Egress -> App Tier on App Port (Completes the path)
resource "aws_security_group_rule" "allow_alb_to_app" {
  type                     = "ingress"
  description              = "Allow traffic from ALB to App on port ${var.app_port}"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}
