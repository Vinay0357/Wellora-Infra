# -----------------------------------------------------------------------------
# Compute Module - EKS Cluster and Node Group Configuration
# -----------------------------------------------------------------------------

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "compute-eks"
    }
  )

  cluster_name = var.cluster_name == "" ? "${var.project_name}-${var.environment}-eks" : var.cluster_name
}

# --- EKS Cluster ---
resource "aws_eks_cluster" "cluster" {
  name     = local.cluster_name
  role_arn = var.eks_cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = distinct(concat(var.private_subnet_ids, var.public_subnet_ids)) # Use both private and public if needed for endpoint/nodes
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []
    security_group_ids      = var.cluster_security_group_ids # Can associate additional SGs if needed
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  tags = merge(local.module_tags, {
    Name = local.cluster_name
  })

  # Ensure IAM Role exists before creating cluster
  depends_on = [
    # Add dependency if IAM role is created in a separate module and passed via ARN
    # aws_iam_role.eks_cluster_role (if role created in same module/root)
  ]
}

# --- EKS OIDC Provider for IRSA ---
# Allows assigning IAM roles directly to Kubernetes Service Accounts
data "tls_certificate" "eks_oidc_thumbprint" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc_thumbprint.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer # Get OIDC issuer URL from cluster

  tags = merge(local.module_tags, {
    Name = "${local.cluster_name}-oidc-provider"
  })
}


# --- EKS Managed Node Group ---
resource "aws_eks_node_group" "default_nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${local.cluster_name}-${var.nodegroup_name}"
  node_role_arn   = var.eks_node_role_arn
  subnet_ids      = var.private_subnet_ids # Deploy worker nodes in private subnets

  ami_type       = var.nodegroup_ami_type
  capacity_type  = var.nodegroup_capacity_type
  disk_size      = var.nodegroup_disk_size
  instance_types = var.nodegroup_instance_types
  # remote_access { # Optional: Allow SSH access - prefer SSM
  #   ec2_ssh_key = var.ssh_key_name
  #   source_security_group_ids = [var.admin_ssh_sg_id] # Security group allowing SSH from admin CIDRs/VPN
  # }

  scaling_config {
    desired_size = var.nodegroup_scaling_desired_size
    min_size     = var.nodegroup_scaling_min_size
    max_size     = var.nodegroup_scaling_max_size
  }

  # Ensure cluster is created before node group
  depends_on = [
    aws_eks_cluster.cluster,
    # Add dependency if IAM role is created in a separate module and passed via ARN
    # aws_iam_role.eks_node_role (if role created in same module/root)
    # Also depend on any policies attached to the node role, especially ECR access
  ]

  tags = merge(local.module_tags, {
    Name = "${local.cluster_name}-${var.nodegroup_name}"
    # EKS requires specific tags for auto-discovery by cluster autoscaler etc.
    "eks:cluster-name"        = local.cluster_name
    "eks:nodegroup-name"      = "${local.cluster_name}-${var.nodegroup_name}"
    # Add tags needed by cluster autoscaler if using it
    #"k8s.io/cluster-autoscaler/enabled": "true",
    #"k8s.io/cluster-autoscaler/${local.cluster_name}": "owned",
  })

  # Update EKS config map - handled automatically by EKS for managed node groups
  # lifecycle {
  #   ignore_changes = [scaling_config[0].desired_size] # Optional: Ignore desired_size if managed by cluster autoscaler
  # }
}

# --- EKS Addons (Optional Management via Terraform) ---
# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name = aws_eks_cluster.cluster.name
#   addon_name   = "vpc-cni"
#   # addon_version = "..." # Specify version or use default
#   resolve_conflicts = "OVERWRITE"
#   tags = merge(local.module_tags, { Name = "${local.cluster_name}-vpc-cni-addon"})
# }

# resource "aws_eks_addon" "coredns" {
#   cluster_name = aws_eks_cluster.cluster.name
#   addon_name   = "coredns"
#   # addon_version = "..." # Specify version or use default
#   resolve_conflicts = "OVERWRITE"
#   tags = merge(local.module_tags, { Name = "${local.cluster_name}-coredns-addon"})
# }

# resource "aws_eks_addon" "kube_proxy" {
#   cluster_name = aws_eks_cluster.cluster.name
#   addon_name   = "kube-proxy"
#   # addon_version = "..." # Specify version or use default
#   resolve_conflicts = "OVERWRITE"
#   tags = merge(local.module_tags, { Name = "${local.cluster_name}-kube-proxy-addon"})
# }
