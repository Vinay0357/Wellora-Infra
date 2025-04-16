# -----------------------------------------------------------------------------
# Persistence Module - ElastiCache (Redis) Configuration
# -----------------------------------------------------------------------------

locals {
  elasticache_enabled = var.create_elasticache_redis
}

# --- ElastiCache Subnet Group ---
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  count = local.elasticache_enabled ? 1 : 0

  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.db_subnet_ids # Typically use DB subnets

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-redis-subnet-group"
    Module  = "persistence"
  })
}

# --- ElastiCache Redis Replication Group ---
# Using Replication Group resource is recommended for Redis for HA features
resource "aws_elasticache_replication_group" "redis_cluster" {
  count = local.elasticache_enabled ? 1 : 0

  replication_group_id          = "${var.project_name}-${var.environment}-redis"
  description                   = "ElastiCache Redis cluster for ${var.project_name}-${var.environment}"
  node_type                     = var.elasticache_node_type
  engine                        = "redis"
  engine_version                = var.elasticache_engine_version
  port                          = 6379
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group[0].name
  security_group_ids            = var.db_security_group_id
  automatic_failover_enabled    = var.elasticache_num_cache_nodes > 1 ? true : false
  multi_az_enabled              = var.elasticache_num_cache_nodes > 1 ? true : false

  dynamic "cluster_mode" {
    for_each = var.elasticache_cluster_mode_enabled ? [1] : []
    content {
      num_node_groups         = var.elasticache_num_cache_nodes
      replicas_per_node_group = var.elasticache_replicas_per_node_group
    }
  }

  at_rest_encryption_enabled  = var.elasticache_at_rest_encryption_enabled
  transit_encryption_enabled  = var.elasticache_transit_encryption_enabled
  kms_key_id                  = var.elasticache_at_rest_encryption_enabled ? var.elasticache_kms_key_arn : null

  snapshot_retention_limit    = 7
  snapshot_window             = "04:00-06:00"
  maintenance_window          = "sun:06:00-sun:07:00"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-redis-cluster"
    Module  = "persistence"
  })

  apply_immediately = false
}

