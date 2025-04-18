# -----------------------------------------------------------------------------
# IAM Module - Main Configuration
# Creates IAM Roles and Policies for EKS, Tasks, etc.
# -----------------------------------------------------------------------------

locals {
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "iam"
    }
  )

  oidc_url_stripped = trimprefix(var.oidc_provider_url, "https://")

  app_task_assume_role_statements = flatten([
    var.oidc_provider_arn != "" && local.oidc_url_stripped != "" ? [
      {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        effect  = "Allow"
        principals = [{
          type        = "Federated"
          identifiers = [var.oidc_provider_arn]
        }]
        condition = [{
          test     = "StringEquals"
          variable = "${local.oidc_url_stripped}:sub"
          values   = ["system:serviceaccount:*:${var.k8s_service_account_name}"]
        }]
      }
    ] : [],
    [
      {
        actions = ["sts:AssumeRole"]
        effect  = "Allow"
        principals = [{
          type        = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }]
      }
    ]
  ])
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# =============================================================================
# EKS Roles (Conditional)
# =============================================================================

resource "aws_iam_role" "eks_cluster_role" {
  for_each = var.create_eks_roles ? var.eks_roles : {}

  name  = each.value.rolename
  path  = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.module_tags, { Name = each.value.rolename })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  for_each = var.create_eks_roles ? aws_iam_role.eks_cluster_role : {}

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = each.value.name
}

# --- EKS Node Group Role ---
resource "aws_iam_role" "eks_node_role" {
  for_each = var.create_eks_roles ? var.eks_node_roles : {}

  name  = each.value.rolename
  path  = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.module_tags, { Name = each.value.rolename })
}

# Standard EKS Node policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  for_each = var.create_eks_roles ? aws_iam_role.eks_node_role : {}

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = each.value.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  for_each = var.create_eks_roles ? aws_iam_role.eks_node_role : {}

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = each.value.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy_attachment" {
  for_each = var.create_eks_roles ? aws_iam_role.eks_node_role : {}

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = each.value.name
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  for_each = var.create_eks_roles && var.attach_ssm_policy_to_nodes ? aws_iam_role.eks_node_role : {}

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = each.value.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  for_each = var.create_eks_roles && var.attach_cloudwatch_agent_policy_to_nodes ? aws_iam_role.eks_node_role : {}

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = each.value.name
}

# =============================================================================
# Application Task Role (EKS Pods / ECS Tasks) (Conditional)
# =============================================================================

data "aws_iam_policy_document" "app_task_assume_role_policy" {
  count = var.create_app_task_role ? 1 : 0

  dynamic "statement" {
    for_each = local.app_task_assume_role_statements
    content {
      actions = statement.value.actions
      effect  = lookup(statement.value, "effect", "Allow")

      dynamic "principals" {
        for_each = lookup(statement.value, "principals", [])
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "condition", [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "app_task_role" {
  count = var.create_app_task_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-app-task-role"
  path  = "/"

  assume_role_policy = data.aws_iam_policy_document.app_task_assume_role_policy[0].json

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-app-task-role" })
}

# --- Base Application Policy Document ---
# --- Base Application Policy Document ---
data "aws_iam_policy_document" "app_task_policy_doc" {
  count = var.create_app_task_role ? 1 : 0

  dynamic "statement" {
    for_each = length(var.s3_general_bucket_arns) > 0 ? [1] : []
    content {
      sid    = "S3GeneralAccess"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      resources = concat(
        var.s3_general_bucket_arns,
        [for arn in var.s3_general_bucket_arns : "${arn}/*"]
      )
    }
  }

  dynamic "statement" {
    for_each = var.s3_static_assets_bucket_arn != "" ? [1] : []
    content {
      sid    = "S3StaticAssetsRead"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        var.s3_static_assets_bucket_arn,
        "${var.s3_static_assets_bucket_arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.dynamodb_table_arns) > 0 ? [1] : []
    content {
      sid    = "DynamoDBAccess"
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      resources = var.dynamodb_table_arns
    }
  }

  statement {
    sid    = "BedrockInvokeAccess"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "TranscribeAccess"
    effect = "Allow"
    actions = [
      "transcribe:StartMedicalScribeJob",
      "transcribe:GetMedicalScribeJob",
      "transcribe:ListMedicalScribeJobs"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ComprehendMedicalAccess"
    effect = "Allow"
    actions = [
      "comprehendmedical:DetectEntitiesV2",
      "comprehendmedical:DetectPHI",
      "comprehendmedical:InferICD10CM",
      "comprehendmedical:InferRxNorm"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "HealthLakeAccess"
    effect = "Allow"
    actions = [
      "healthlake:GetFHIRDatastore",
      "healthlake:SearchFHIRResources",
      "healthlake:CreateFHIRResource",
      "healthlake:UpdateFHIRResource",
      "healthlake:DeleteFHIRResource",
      "healthlake:ReadFHIRResource"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:healthlake:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:datastore/*"]
  }

  statement {
    sid    = "SNSPublishAccess"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.project_name}-${var.environment}-*"]
  }

  statement {
    sid    = "SESSendAccess"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.kms_key_arns_for_encryption) > 0 ? [1] : []
    content {
      sid    = "KMSDecryptAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ]
      resources = var.kms_key_arns_for_encryption
    }
  }

  statement {
    sid    = "VPCEndpointInteraction"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribePrefixLists"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "app_task_policy" {
  count = var.create_app_task_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-app-task-policy"
  path  = "/"
  description = "Policy granting application tasks access to required AWS services."

  policy = data.aws_iam_policy_document.app_task_policy_doc[0].json

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-app-task-policy" })
}

resource "aws_iam_role_policy_attachment" "app_task_policy_attachment" {
  count      = var.create_app_task_role ? 1 : 0
  policy_arn = aws_iam_policy.app_task_policy[0].arn
  role       = aws_iam_role.app_task_role[0].name
}