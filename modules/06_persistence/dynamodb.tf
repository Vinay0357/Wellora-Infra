# -----------------------------------------------------------------------------
# Persistence Module - DynamoDB Configuration
# -----------------------------------------------------------------------------

locals {
  dynamodb_enabled = var.create_dynamodb_tables && length(keys(var.dynamodb_tables)) > 0
}

resource "aws_dynamodb_table" "tables" {
  # Create a table for each entry in the dynamodb_tables map
  for_each = var.create_dynamodb_tables ? var.dynamodb_tables : {}

  name         = "${var.project_name}-${var.environment}-${each.key}" # Construct table name
  billing_mode = each.value.billing_mode

  # Handle Provisioned throughput if specified
  read_capacity  = each.value.billing_mode == "PROVISIONED" ? each.value.read_capacity : null
  write_capacity = each.value.billing_mode == "PROVISIONED" ? each.value.write_capacity : null

  hash_key  = each.value.hash_key
  range_key = lookup(each.value, "range_key", null) # Use lookup for optional range key

  # Define attributes based on the input map
  dynamic "attribute" {
    for_each = each.value.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Server Side Encryption
  server_side_encryption {
    enabled     = lookup(each.value, "sse_enabled", true)
    kms_key_arn = lookup(each.value, "sse_enabled", true) ? lookup(each.value, "kms_key_arn", null) : null # Apply KMS key only if SSE enabled
  }

  # Point-in-Time Recovery
  point_in_time_recovery {
    enabled = lookup(each.value, "enable_pitr", true)
  }

  # Add other configurations like ttl, global_secondary_index, local_secondary_index as needed
  # Example GSI:
  # dynamic "global_secondary_index" {
  #   for_each = lookup(each.value, "global_secondary_indexes", {})
  #   content {
  #     name            = global_secondary_index.key
  #     hash_key        = global_secondary_index.value.hash_key
  #     range_key       = lookup(global_secondary_index.value, "range_key", null)
  #     projection_type = global_secondary_index.value.projection_type # ALL, KEYS_ONLY, INCLUDE
  #     # non_key_attributes = projection_type == "INCLUDE" ? global_secondary_index.value.non_key_attributes : null
  #     read_capacity  = each.value.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", 5) : null
  #     write_capacity = each.value.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", 5) : null
  #   }
  # }

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-${each.key}"
    Module  = "persistence"
  })
}
