# -----------------------------------------------------------------------------
# Outputs from the iam module
# -----------------------------------------------------------------------------

output "eks_cluster_role_arn" {
  description = "ARN of the EKS Cluster IAM Role"
  value       = length(aws_iam_role.eks_cluster_role) > 0 ? aws_iam_role.eks_cluster_role[0].arn : null
}

output "eks_node_role_arn" {
  description = "ARN of the EKS Node Group IAM Role"
  value       = length(aws_iam_role.eks_node_role) > 0 ? aws_iam_role.eks_node_role[0].arn : null
}

output "eks_node_role_name" {
  description = "Name of the EKS Node Group IAM Role"
  value       = length(aws_iam_role.eks_node_role) > 0 ? aws_iam_role.eks_node_role[0].name : null
}

output "app_task_role_arn" {
  description = "ARN of the Application Task/Pod IAM Role"
  value       = length(aws_iam_role.app_task_role) > 0 ? aws_iam_role.app_task_role[0].arn : null
}

output "app_task_role_name" {
  description = "Name of the Application Task/Pod IAM Role"
  value       = length(aws_iam_role.app_task_role) > 0 ? aws_iam_role.app_task_role[0].name : null
}