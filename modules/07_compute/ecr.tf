# -----------------------------------------------------------------------------
# Compute Module - ECR Repository Configuration
# -----------------------------------------------------------------------------

locals {
  ecr_enabled = var.create_ecr_repos && length(var.ecr_repository_names) > 0
}

resource "aws_ecr_repository" "app_repos" {
  for_each = local.ecr_enabled ? { for repo in var.ecr_repository_names : repo => repo } : {}

  # Construct name: project/env/repo_base_name (e.g., wellora/prod/frontend-app)
  name = lower("${var.project_name}/${var.environment}/${each.key}")

  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  # Optional: Add lifecycle policy to clean up old images
  # lifecycle_policy = jsonencode({ ... })

  tags = merge(var.common_tags, {
    Name    = lower("${var.project_name}-${var.environment}-${each.key}")
    Module  = "compute-ecr"
  })
}

