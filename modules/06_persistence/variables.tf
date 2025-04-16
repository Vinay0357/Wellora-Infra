# -----------------------------------------------------------------------------
# Input variables for the persistence module
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of private subnet IDs designated for database layers (RDS, ElastiCache)"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "The ID of the security group to associate with RDS and ElastiCache instances"
  type        = list(string) # Needs to be list for ElastiCache/RDS
}

# --- RDS Configuration ---

variable "create_rds" {
  description = "Set to true to create an RDS instance"
  type        = bool
  default     = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS database"
  type        = string
  default     = "db.t3.micro" # Example, choose based on needs
}

variable "db_engine" {
  description = "Database engine (e.g., postgres, mysql, oracle-se2, sqlserver-ex)"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "14.10" # Example for PostgreSQL 14 - check latest supported
}

variable "db_allocated_storage" {
  description = "Allocated storage size in GB for RDS"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database to create in RDS"
  type        = string
  default     = "welloradb"
}

variable "db_username" {
  description = "Master username for the RDS database"
  type        = string
  default     = "welloraadmin"
}

variable "db_password" {
  description = "Master password for the RDS database. IMPORTANT: Populate securely using env var (TF_VAR_db_password) or replace with data source lookup (Secrets Manager/SSM)"
  type        = string
  sensitive   = true # Marks the variable as sensitive in Terraform output/logs
  # default = "" # No default for sensitive values
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS for high availability"
  type        = bool
  default     = true # Recommended for prod
}

variable "rds_backup_retention_period" {
  description = "Backup retention period in days for RDS (0 to disable)"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection for the RDS instance"
  type        = bool
  default     = true # Recommended for prod
}

variable "rds_kms_key_arn" {
  description = "ARN of the KMS key for RDS storage encryption (if null, uses default AWS key)"
  type        = string
  default     = null
}

variable "rds_storage_encrypted" {
  description = "Enable storage encryption for RDS"
  type        = bool
  default     = true
}

# --- ElastiCache (Redis Example) ---

variable "create_elasticache_redis" {
  description = "Set to true to create an ElastiCache Redis cluster"
  type        = bool
  default     = true
}

variable "elasticache_node_type" {
  description = "Node type for ElastiCache nodes (e.g., cache.t3.micro)"
  type        = string
  default     = "cache.t3.micro" # Example, choose based on needs
}

variable "elasticache_engine_version" {
  description = "Engine version for ElastiCache Redis"
  type        = string
  default     = "7.0" # Example for Redis - check latest supported
}

variable "elasticache_num_cache_nodes" {
  description = "Number of nodes in the Redis cluster (if cluster_mode disabled) or number of node groups (if cluster_mode enabled)"
  type        = number
  default     = 1 # Set > 1 for replicas/shards depending on cluster mode
}

variable "elasticache_replicas_per_node_group" {
  description = "Number of replica nodes in each node group (shard). Used only if cluster_mode is enabled."
  type        = number
  default     = 1 # Creates Primary + 1 Replica per shard
}

variable "elasticache_cluster_mode_enabled" {
  description = "Specifies whether cluster mode is enabled (Redis partitioning/sharding)."
  type        = bool
  default     = false # Set to true for sharded Redis cluster
}

variable "elasticache_kms_key_arn" {
  description = "ARN of the KMS key for ElastiCache encryption at rest (if null, uses default AWS key)"
  type        = string
  default     = null
}

variable "elasticache_at_rest_encryption_enabled" {
  description = "Enable encryption at rest for ElastiCache"
  type        = bool
  default     = true
}

variable "elasticache_transit_encryption_enabled" {
  description = "Enable encryption in transit for ElastiCache (requires TLS)"
  type        = bool
  default     = true
}

# --- DynamoDB Configuration ---

variable "create_dynamodb_tables" {
  description = "Set to true to create DynamoDB tables defined in the module"
  type        = bool
  default     = true
}

variable "dynamodb_tables" {
  description = "Map of DynamoDB tables to create. Key is logical name, value contains attributes, hash_key, range_key (optional), billing_mode, etc."
  type = map(object({
    attributes = list(object({
      name = string
      type = string # S (String), N (Number), B (Binary)
    }))
    hash_key     = string
    range_key    = optional(string)
    billing_mode = optional(string, "PAY_PER_REQUEST") # PAY_PER_REQUEST or PROVISIONED
    read_capacity  = optional(number, 5) # Required if billing_mode is PROVISIONED
    write_capacity = optional(number, 5) # Required if billing_mode is PROVISIONED
    enable_pitr    = optional(bool, true) # Point-in-Time Recovery
    sse_enabled    = optional(bool, true)
    kms_key_arn    = optional(string) # Optional KMS key for SSE
    # Add stream_enabled, stream_view_type, global_secondary_indexes, local_secondary_indexes if needed
  }))
  default = {
    # Example table definition - customize as needed
    "WelloraAppTable" = {
      attributes = [
        { name = "PartitionKey", type = "S" },
        { name = "SortKey", type = "S" },
        { name = "Data", type = "S" } # Example attribute
      ]
      hash_key     = "PartitionKey"
      range_key    = "SortKey"
      billing_mode = "PAY_PER_REQUEST"
      enable_pitr  = true
      sse_enabled  = true
      kms_key_arn  = null # Uses AWS owned key by default if null
    }
  }
}

# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
