# -----------------------------------------------------------------------------
# Load Balancing Module - Main Configuration (ALB)
# -----------------------------------------------------------------------------

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "load_balancing"
    }
  )

  alb_name = var.alb_name == "" ? "${var.project_name}-${var.environment}-alb" : var.alb_name
}

# --- Application Load Balancer ---
resource "aws_lb" "alb" {
  name               = local.alb_name
  internal           = var.is_internal_alb
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_id
  subnets            = var.public_subnet_ids # ALB deployed in public subnets

  enable_deletion_protection = var.enable_alb_deletion_protection

  # Access Logs Configuration
  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs && var.access_logs_s3_bucket_name != "" ? [1] : []
    content {
      bucket  = var.access_logs_s3_bucket_name
      prefix  = var.access_logs_s3_prefix
      enabled = true
    }
  }

  tags = merge(local.module_tags, {
    Name = local.alb_name
  })
}

# --- Target Group ---
# Targets (pods) are typically registered by the AWS Load Balancer Controller in EKS
resource "aws_lb_target_group" "app_tg" {
  name        = "${local.alb_name}-tg" # Target group name
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  target_type = var.target_type # 'ip' for EKS pods
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = var.health_check_protocol
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    matcher             = var.health_check_matcher
  }

  # Deregistration delay - adjust as needed
  deregistration_delay = 60

  tags = merge(local.module_tags, {
    Name = "${local.alb_name}-tg"
  })

  # Add lifecycle rule if using Blue/Green deployments with CodeDeploy
  # lifecycle {
  #   create_before_destroy = true
  # }
}

# --- HTTPS Listener (Port 443) ---
resource "aws_lb_listener" "https_listener" {
  count = var.enable_https_listener && var.acm_certificate_arn != null ? 1 : 0

  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn # REQUIRED

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = merge(local.module_tags, {
    Name = "${local.alb_name}-listener-https"
  })
}


# --- HTTP Listener (Port 80) ---
resource "aws_lb_listener" "http_listener" {
  count = var.enable_http_listener ? 1 : 0

  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  # Default Action: Redirect HTTP to HTTPS if enabled, otherwise forward to target group
  default_action {
    type = var.http_to_https_redirect && var.enable_https_listener && var.acm_certificate_arn != null ? "redirect" : "forward"

    # Forward settings (used if redirect disabled or HTTPS not configured)
    target_group_arn = var.http_to_https_redirect && var.enable_https_listener && var.acm_certificate_arn != null ? null : aws_lb_target_group.app_tg.arn

    # Redirect settings (used if redirect enabled and HTTPS configured)
    dynamic "redirect" {
      for_each = var.http_to_https_redirect && var.enable_https_listener && var.acm_certificate_arn != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301" # Permanent redirect
      }
    }
  }

  tags = merge(local.module_tags, {
    Name = "${local.alb_name}-listener-http"
  })
}
