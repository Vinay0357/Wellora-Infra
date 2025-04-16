# -----------------------------------------------------------------------------
# AI Services Module - Main Configuration (HealthLake Datastore)
# Note: Bedrock, Transcribe, Comprehend configuration is primarily IAM + VPC Endpoints
# which should be handled in modules 04_iam and 03_vpc_endpoints respectively.
# -----------------------------------------------------------------------------

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "ai_services"
    }
  )

  healthlake_enabled = var.create_healthlake_datastore
  datastore_name     = var.healthlake_datastore_name == "" ? "${var.project_name}-${var.environment}-fhir-store" : var.healthlake_datastore_name
}

# --- Amazon HealthLake FHIR Datastore ---
resource "aws_healthlake_fhir_datastore" "datastore" {
  count = local.healthlake_enabled ? 1 : 0

  name                = local.datastore_name
  datastore_type_version = var.healthlake_datastore_type_version

  # Server-Side Encryption configuration
  sse_configuration {
    kms_encryption_config {
      cmk_type   = var.healthlake_sse_kms_key_arn == null ? "AWS_OWNED_KMS_KEY" : "CUSTOMER_MANAGED_KMS_KEY"
      kms_key_id = var.healthlake_sse_kms_key_arn # Use specified key or null for AWS owned
    }
  }

  # Preload data configuration (optional)
  dynamic "preload_data_config" {
    for_each = var.healthlake_preload_data_config != null ? [var.healthlake_preload_data_config] : []
    content {
      preload_data_type = preload_data_config.value.preload_data_type
    }
  }

  tags = merge(local.module_tags, {
    Name = local.datastore_name
  })
}
