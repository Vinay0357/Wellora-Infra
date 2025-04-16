# -----------------------------------------------------------------------------
# Outputs from the persistence module
# -----------------------------------------------------------------------------

# --- RDS Outputs ---
output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].id : null
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].arn : null
}

output "rds_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].endpoint : null
}

output "rds_instance_port" {
  description = "The port the RDS instance is listening on"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].port : null
}

output "rds_db_name" {
  description = "The database name (logical database) for the RDS instance"
  value       = length(aws_db_instance.rds_instance) > 0 ? aws_db_instance.rds_instance[0].db_name : null
}

# --- ElastiCache Outputs ---
output "elasticache_redis_replication_group_id" {
  description = "The ID of the ElastiCache Redis replication group"
  value       = length(aws_elasticache_replication_group.redis_cluster) > 0 ? aws_elasticache_replication_group.redis_cluster[0].id : null
}

output "elasticache_redis_primary_endpoint_address" {
  description = "The connection endpoint address for the primary node in the Redis replication group"
  value       = length(aws_elasticache_replication_group.redis_cluster) > 0 ? aws_elasticache_replication_group.redis_cluster[0].primary_endpoint_address : null
}

output "elasticache_redis_reader_endpoint_address" {
  description = "The reader endpoint address for the Redis replication group (for read replicas)"
  value       = length(aws_elasticache_replication_group.redis_cluster) > 0 ? aws_elasticache_replication_group.redis_cluster[0].reader_endpoint_address : null
}

output "elasticache_redis_port" {
  description = "The port for the ElastiCache Redis cluster"
  value       = length(aws_elasticache_replication_group.redis_cluster) > 0 ? aws_elasticache_replication_group.redis_cluster[0].port : null
}

# --- DynamoDB Outputs ---
output "dynamodb_table_names" {
  description = "Map of logical table names to actual DynamoDB table names"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.name }
}

output "dynamodb_table_arns" {
  description = "Map of logical table names to DynamoDB table ARNs"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.arn }
}

output "dynamodb_table_ids" {
  description = "Map of logical table names to DynamoDB table IDs"
  value       = { for k, v in aws_dynamodb_table.tables : k => v.id }
}
