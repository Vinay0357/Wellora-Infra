# -----------------------------------------------------------------------------
# IAM Module - Main Configuration
# Creates IAM Roles and Policies for EKS, Tasks, etc.
# -----------------------------------------------------------------------------

locals {
  # Construct common tags by merging defaults and module-specific tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "iam"
    }
  )

  # Extract OIDC provider URL without https:// prefix if provided
  oidc_url_stripped = trimprefix(var.oidc_provider_url, "https://")

  # Build list of assume role policy statements conditionally
  app_task_assume_role_statements = flatten([
    # EKS OIDC statement (if configured)
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
          values   = ["system:serviceaccount:*:${var.k8s_service_account_name}"] # Example: Restrict to specific SA name
        }]
        # Optional condition for audience
        # condition = [{
        #   test     = "StringEquals"
        #   variable = "${local.oidc_url_stripped}:aud"
        #   values   = ["sts.amazonaws.com"]
        # }]
      }
    ] : [],
    # ECS Tasks statement (include if needed, e.g., if not using EKS or OIDC not set)
    # If using only EKS+IRSA, this can potentially be removed
    # var.oidc_provider_arn == "" || var.oidc_url_stripped == "" ? [
    [ # Always include ECS Task role principal if create_app_task_role is true, adjust logic if exclusively EKS/IRSA
      {
        actions = ["sts:AssumeRole"]
        effect  = "Allow"
        principals = [{
          type        = "Service"
          identifiers = ["ecs-tasks.amazonaws.com"]
        }]
      }
    ] # : [], # Removed conditional logic here, assuming task role might be used by ECS too, refine if needed.
  ])
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}


# =============================================================================
# EKS Roles (Conditional)
# =============================================================================

# --- EKS Cluster Role ---
resource "aws_iam_role" "eks_cluster_role" {
  count = var.create_eks_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks-cluster-role"
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

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-eks-cluster-role" })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  count      = var.create_eks_roles ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role[0].name
}

# --- EKS Node Group Role ---
resource "aws_iam_role" "eks_node_role" {
  count = var.create_eks_roles ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eks-node-role"
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

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-eks-node-role" })
}

# Standard EKS Node policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  count      = var.create_eks_roles ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  count      = var.create_eks_roles ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy" # Required for VPC CNI plugin
  role       = aws_iam_role.eks_node_role[0].name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy_attachment" {
  count      = var.create_eks_roles ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # Required to pull images
  role       = aws_iam_role.eks_node_role[0].name
}

# Optional: SSM Policy for node management
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  count      = var.create_eks_roles && var.attach_ssm_policy_to_nodes ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_role[0].name
}

# Optional: CloudWatch Agent Policy for node monitoring
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  count      = var.create_eks_roles && var.attach_cloudwatch_agent_policy_to_nodes ? 1 : 0
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_node_role[0].name
}


# =============================================================================
# Application Task Role (EKS Pods / ECS Tasks) (Conditional)
# =============================================================================

# Define Assume Role Policy Document using the conditional statements from locals
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
data "aws_iam_policy_document" "app_task_policy_doc" {
  count = var.create_app_task_role ? 1 : 0

  # S3 Access (General Buckets - Read/Write)
  statement {
    sid    = "S3GeneralAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket" # Be cautious with ListBucket on large buckets
    ]
    resources = length(var.s3_general_bucket_arns) > 0 ? concat(
      var.s3_general_bucket_arns,                                                 # Bucket level access
      [for arn in var.s3_general_bucket_arns : "${arn}/*"]                        # Object level access
    ) : [] # Prevent error if list is empty
    # Condition = {} # Add conditions if needed (e.g., specific prefixes)
  }

  # S3 Access (Static Assets Bucket - Read Only)
  statement {
    sid    = "S3StaticAssetsRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = var.s3_static_assets_bucket_arn != "" ? [
      var.s3_static_assets_bucket_arn,
      "${var.s3_static_assets_bucket_arn}/*"
    ] : []
  }

  # DynamoDB Access
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
      # Add more specific actions as needed
    ]
    resources = length(var.dynamodb_table_arns) > 0 ? var.dynamodb_table_arns : [] # Prevent error if list empty
  }

  # Bedrock Access
  statement {
    sid    = "BedrockInvokeAccess"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel"
      # Add other Bedrock actions if needed (e.g., ListFoundationModels)
    ]
    resources = ["*"] # Bedrock actions often apply to all models, refine if specific models needed
  }

  # Transcribe Access
  statement {
    sid    = "TranscribeAccess"
    effect = "Allow"
    actions = [
      "transcribe:StartMedicalScribeJob",
      "transcribe:GetMedicalScribeJob",
      "transcribe:ListMedicalScribeJobs"
      # Add StartTranscriptionJob etc. if needed
    ]
    resources = ["*"] # Transcribe jobs are regional resources
  }

  # Comprehend Medical Access
  statement {
    sid    = "ComprehendMedicalAccess"
    effect = "Allow"
    actions = [
      "comprehendmedical:DetectEntitiesV2",
      "comprehendmedical:DetectPHI",
      "comprehendmedical:InferICD10CM",
      "comprehendmedical:InferRxNorm"
      # Add more actions as needed
    ]
    resources = ["*"] # Actions are typically not resource-specific
  }

  # HealthLake Access (Example: Read/Write)
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
    # HealthLake datastore ARN format: arn:aws:healthlake:<region>:<account-id>:datastore/<datastore-id>/* (Note the /* for resource access)
    resources = ["arn:${data.aws_partition.current.partition}:healthlake:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:datastore/*"] # Adjust if specific datastore ID is known and passed in
  }

  # SNS Publish Access
  statement {
    sid    = "SNSPublishAccess"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    # Specify specific SNS topic ARNs if known / passed in
    resources = ["arn:${data.aws_partition.current.partition}:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.project_name}-${var.environment}-*"] # Example pattern, better to pass exact ARNs
  }

  # SES Send Access
  statement {
    sid    = "SESSendAccess"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    # SES sending authorization can be complex (identities, configuration sets)
    # Resource should be the verified identity ARN (domain or email)
    # Example: "arn:aws:ses:REGION:ACCOUNTID:identity/yourdomain.com"
    resources = ["*"] # Typically applies to authorized sender identities, refine if possible
  }

  # KMS Decrypt Access (If using CMKs for S3, HealthLake, etc.)
  # Using dynamic block for the statement itself
  dynamic "statement" {
    for_each = length(var.kms_key_arns_for_encryption) > 0 ? [1] : [] # Only create if KMS keys are specified
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

  # Allow interaction with VPC endpoints (needed if using private DNS)
  statement {
    sid    = "VPCEndpointInteraction"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribePrefixLists" # Needed for S3/DynamoDB Gateway endpoints
      # Add other ec2:Describe* actions if needed by specific clients/SDKs
    ]
    resources = ["*"]
  }
}

# Create the IAM Policy from the document
resource "aws_iam_policy" "app_task_policy" {
  count = var.create_app_task_role ? 1 : 0
  name  = "${var.project_name}-${var.environment}-app-task-policy"
  path  = "/"
  description = "Policy granting application tasks access to required AWS services."

  policy = data.aws_iam_policy_document.app_task_policy_doc[0].json

  tags = merge(local.module_tags, { Name = "${var.project_name}-${var.environment}-app-task-policy" })
}

# Attach the custom policy to the App Task Role
resource "aws_iam_role_policy_attachment" "app_task_policy_attachment" {
  count      = var.create_app_task_role ? 1 : 0
  policy_arn = aws_iam_policy.app_task_policy[0].arn
  role       = aws_iam_role.app_task_role[0].name
}