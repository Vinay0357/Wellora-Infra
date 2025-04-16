# -----------------------------------------------------------------------------
# S3 Module - Main Configuration
# Creates buckets for static assets, raw audio, transcripts, and optionally logging
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_canonical_user_id" "current" {} # Needed for log delivery policy

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "s3"
    }
  )

  # Bucket Naming Convention: project-env-suffix-accountid-region (ensures global uniqueness)
  account_id = data.aws_caller_identity.current.account_id
  region     = var.aws_region

  static_assets_bucket_name = lower("${var.project_name}-${var.environment}-${var.static_assets_bucket_name_suffix}-${local.account_id}-${local.region}")
  raw_audio_bucket_name     = lower("${var.project_name}-${var.environment}-${var.raw_audio_bucket_name_suffix}-${local.account_id}-${local.region}")
  transcripts_bucket_name   = lower("${var.project_name}-${var.environment}-${var.transcripts_bucket_name_suffix}-${local.account_id}-${local.region}")
  access_log_bucket_name    = lower("${var.project_name}-${var.environment}-${var.access_log_bucket_name_suffix}-${local.account_id}-${local.region}")

  # Determine the target log bucket ID
  log_bucket_id = var.enable_access_logging ? (var.create_access_log_bucket ? local.access_log_bucket_name : var.existing_access_log_bucket_id) : null

  # KMS Key ARN logic
  kms_master_key_id = var.encryption_type == "aws:kms" ? var.kms_key_arn : null
}

# --- Optional: Access Log Bucket ---
resource "aws_s3_bucket" "log_bucket" {
  count = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0

  bucket        = local.access_log_bucket_name
  force_destroy = var.force_destroy_buckets # Use with caution

  tags = merge(local.module_tags, { Name = local.access_log_bucket_name })
}

resource "aws_s3_bucket_ownership_controls" "log_bucket_controls" {
  count  = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  rule {
    object_ownership = "BucketOwnerPreferred" # Recommended for log delivery
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_block" {
  count  = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  count  = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Use SSE-S3 for log bucket simplicity
    }
  }
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_controls]
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  count  = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    id     = "ExpireOldLogs"
    status = "Enabled"
    expiration {
      days = 365 # Expire logs after 1 year
    }
  }
  depends_on = [aws_s3_bucket.log_bucket]
}

# Policy to allow log delivery service to write to the log bucket
data "aws_iam_policy_document" "log_bucket_policy_doc" {
  count = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0

  statement {
    sid    = "AllowLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.access_log_bucket_name}/*"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      # Allow logs from any bucket in the account - scope down if needed
      values = ["arn:aws:s3:::*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  count  = var.enable_access_logging && var.create_access_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id
  policy = data.aws_iam_policy_document.log_bucket_policy_doc[0].json
}


# --- Static Assets Bucket ---
resource "aws_s3_bucket" "static_assets" {
  bucket        = local.static_assets_bucket_name
  force_destroy = var.force_destroy_buckets

  tags = merge(local.module_tags, { Name = local.static_assets_bucket_name })
}

resource "aws_s3_bucket_versioning" "static_assets_versioning" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets_encryption" {
  bucket = aws_s3_bucket.static_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = local.kms_master_key_id # Null if AES256
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets_block" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = var.static_assets_block_public_access
  block_public_policy     = var.static_assets_block_public_access
  ignore_public_acls      = var.static_assets_block_public_access
  restrict_public_buckets = var.static_assets_block_public_access
}

resource "aws_s3_bucket_logging" "static_assets_logging" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.static_assets.id
  target_bucket = local.log_bucket_id # Use the created or specified log bucket
  target_prefix = var.log_file_prefix_static
  depends_on = [
    # Ensure log bucket exists and policy is applied before enabling logging
    aws_s3_bucket.log_bucket,
    aws_s3_bucket_policy.log_bucket_policy
  ]
}

resource "aws_s3_bucket_cors_configuration" "static_assets_cors" {
  count = var.enable_cors_static_assets ? 1 : 0

  bucket = aws_s3_bucket.static_assets.id
  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = [] # Add headers if needed e.g., ["ETag"]
    max_age_seconds = var.cors_max_age_seconds
  }
}

# Note: Add aws_s3_bucket_policy here if needed for CloudFront OAI/OAC


# --- Raw Audio Bucket ---
resource "aws_s3_bucket" "raw_audio" {
  bucket        = local.raw_audio_bucket_name
  force_destroy = var.force_destroy_buckets

  tags = merge(local.module_tags, { Name = local.raw_audio_bucket_name })
}

resource "aws_s3_bucket_versioning" "raw_audio_versioning" {
  bucket = aws_s3_bucket.raw_audio.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_audio_encryption" {
  bucket = aws_s3_bucket.raw_audio.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = local.kms_master_key_id
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_audio_block" {
  bucket = aws_s3_bucket.raw_audio.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_logging" "raw_audio_logging" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.raw_audio.id
  target_bucket = local.log_bucket_id
  target_prefix = var.log_file_prefix_raw_audio
  depends_on = [
    aws_s3_bucket.log_bucket,
    aws_s3_bucket_policy.log_bucket_policy
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_audio_lifecycle" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.raw_audio.id

  # Rule to transition current versions
  rule {
    id     = "TransitionToIA"
    status = "Enabled"
    filter {} # Apply to all objects
    transition {
      days          = var.ia_transition_days
      storage_class = "STANDARD_IA" # Or INTELLIGENT_TIERING
    }
  }

  # Rule to expire noncurrent versions
  rule {
    id     = "ExpireNoncurrent"
    status = var.enable_versioning ? "Enabled" : "Disabled"
    filter {} # Apply to all objects
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  # Rule to abort incomplete multipart uploads
  rule {
    id     = "AbortIncompleteMultipart"
    status = "Enabled"
    filter {} # Apply to all objects
    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
  depends_on = [aws_s3_bucket_versioning.raw_audio_versioning]
}


# --- Transcripts Bucket ---
resource "aws_s3_bucket" "transcripts" {
  bucket        = local.transcripts_bucket_name
  force_destroy = var.force_destroy_buckets

  tags = merge(local.module_tags, { Name = local.transcripts_bucket_name })
}

resource "aws_s3_bucket_versioning" "transcripts_versioning" {
  bucket = aws_s3_bucket.transcripts.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "transcripts_encryption" {
  bucket = aws_s3_bucket.transcripts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = local.kms_master_key_id
    }
  }
}

resource "aws_s3_bucket_public_access_block" "transcripts_block" {
  bucket = aws_s3_bucket.transcripts.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_logging" "transcripts_logging" {
  count = var.enable_access_logging ? 1 : 0

  bucket        = aws_s3_bucket.transcripts.id
  target_bucket = local.log_bucket_id
  target_prefix = var.log_file_prefix_transcripts
  depends_on = [
    aws_s3_bucket.log_bucket,
    aws_s3_bucket_policy.log_bucket_policy
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "transcripts_lifecycle" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.transcripts.id

  # Rule to transition current versions
  rule {
    id     = "TransitionToIA"
    status = "Enabled"
    filter {} # Apply to all objects
    transition {
      days          = var.ia_transition_days
      storage_class = "STANDARD_IA" # Or INTELLIGENT_TIERING
    }
  }

  # Rule to expire noncurrent versions
  rule {
    id     = "ExpireNoncurrent"
    status = var.enable_versioning ? "Enabled" : "Disabled"
    filter {} # Apply to all objects
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }

  # Rule to abort incomplete multipart uploads
  rule {
    id     = "AbortIncompleteMultipart"
    status = "Enabled"
    filter {} # Apply to all objects
    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
  depends_on = [aws_s3_bucket_versioning.transcripts_versioning]
}