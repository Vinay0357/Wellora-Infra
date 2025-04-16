# -----------------------------------------------------------------------------
# Persistence Module - RDS Configuration
# -----------------------------------------------------------------------------

locals {
  rds_enabled = var.create_rds
}

# --- DB Subnet Group ---
resource "aws_db_subnet_group" "rds_subnet_group" {
  count = local.rds_enabled ? 1 : 0

  name       = "${var.project_name}-${var.environment}-rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-rds-subnet-group"
    Module  = "persistence"
  })
}

# --- RDS DB Instance ---
resource "aws_db_instance" "rds_instance" {
  count = local.rds_enabled ? 1 : 0

  identifier           = "${var.project_name}-${var.environment}-rds"
  allocated_storage    = var.db_allocated_storage
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password # SENSITIVE: Ensure this is populated securely
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group[0].name
  vpc_security_group_ids = var.db_security_group_id # Attach the DB Tier SG
  parameter_group_name = null # Use default, or create aws_db_parameter_group

  backup_retention_period = var.rds_backup_retention_period
  multi_az                = var.rds_multi_az
  storage_encrypted       = var.rds_storage_encrypted
  kms_key_id              = var.rds_kms_key_arn # Use specified KMS key or AWS default if null
  deletion_protection     = var.rds_deletion_protection

  skip_final_snapshot = var.environment == "prod" ? false : true # Skip snapshot for non-prod on destroy
  apply_immediately   = false # Apply changes during maintenance window unless specified

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-rds-instance"
    Module  = "persistence"
  })

  # Prevent Terraform from storing the password in state (already marked sensitive)
  lifecycle {
    ignore_changes = [password]
  }
}