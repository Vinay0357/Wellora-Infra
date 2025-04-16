# -----------------------------------------------------------------------------
# Outputs from the security_groups module
# -----------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "The ID of the Application Load Balancer security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "The ID of the Application Tier security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "The ID of the Database Tier security group"
  value       = aws_security_group.db.id
}