# -----------------------------------------------------------------------------
# Outputs from the iam module
# -----------------------------------------------------------------------------

output "eks_cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM Role"
  value       = { for key, role in aws_iam_role.eks_cluster_role : key => role.arn }
}

output "eks_node_role_arn" {
  description = "ARN of the EKS Node Group IAM Role"
  value       = { for key, role in aws_iam_role.eks_node_role : key => role.arn }
}

output "eks_node_role_name" {
  description = "Name of the EKS Node Group IAM Role"
  value       = { for key, role in aws_iam_role.eks_node_role : key => role.name }
}

output "app_task_role_arn" {
  description = "ARN of the Application Task/Pod IAM Role"
  value       = length(aws_iam_role.app_task_role) > 0 ? aws_iam_role.app_task_role[0].arn : null
}

output "app_task_role_name" {
  description = "Name of the Application Task/Pod IAM Role"
  value       = length(aws_iam_role.app_task_role) > 0 ? aws_iam_role.app_task_role[0].name : null
}

# Outputs for EKS Cluster Roles
output "eks_cluster_roles" {
  description = "Map of created EKS cluster roles"
  value       = { for key, role in aws_iam_role.eks_cluster_role : key => role.name }
}

# Outputs for EKS Node Roles
output "eks_node_roles" {
  description = "Map of created EKS node roles"
  value       = { for key, role in aws_iam_role.eks_node_role : key => role.name }
}

# Optional: Output for Application Task Role
output "app_task_role" {
  description = "Name of the created application task role"
  value       = length(aws_iam_role.app_task_role) > 0 ? aws_iam_role.app_task_role[0].name : null
}

# Optional: Output for Application Task Policy
output "app_task_policy" {
  description = "ARN of the created application task policy"
  value       = length(aws_iam_policy.app_task_policy) > 0 ? aws_iam_policy.app_task_policy[0].arn : null
}