# -----------------------------------------------------------------------------
# Outputs from the compute module
# -----------------------------------------------------------------------------

# --- EKS Outputs ---
output "eks_cluster_id" {
  description = "The name/ID of the EKS cluster"
  value       = aws_eks_cluster.cluster.id
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.cluster.arn
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster's Kubernetes API server"
  value       = aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Identity Provider for the EKS cluster (used for IRSA)"
  value       = aws_iam_openid_connect_provider.eks_oidc_provider.arn
}

output "eks_oidc_provider_url" {
  description = "URL of the OIDC Identity Provider for the EKS cluster"
  value       = aws_iam_openid_connect_provider.eks_oidc_provider.url
}

output "eks_nodegroup_id" {
  description = "The ID of the default EKS managed node group"
  value       = aws_eks_node_group.default_nodes.id
}

output "eks_nodegroup_arn" {
  description = "The ARN of the default EKS managed node group"
  value       = aws_eks_node_group.default_nodes.arn
}

output "eks_nodegroup_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.default_nodes.status
}


# --- ECR Outputs ---
output "ecr_repository_urls" {
  description = "Map of ECR repository base names to their repository URLs"
  value       = { for repo in aws_ecr_repository.app_repos : replace(repo.name, "${var.project_name}/${var.environment}/", "") => repo.repository_url }
}

output "ecr_repository_arns" {
  description = "Map of ECR repository base names to their repository ARNs"
  value       = { for repo in aws_ecr_repository.app_repos : replace(repo.name, "${var.project_name}/${var.environment}/", "") => repo.arn }
}
