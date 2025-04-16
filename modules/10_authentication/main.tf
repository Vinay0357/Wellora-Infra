# -----------------------------------------------------------------------------
# Authentication Module - Main Configuration (Cognito User Pool & Client)
# -----------------------------------------------------------------------------

locals {
  # Construct common tags
  module_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "Terraform"   = "true"
      "Module"      = "authentication"
    }
  )

  user_pool_name = var.user_pool_name == "" ? "${var.project_name}-${var.environment}-users" : var.user_pool_name
  domain_prefix  = var.user_pool_domain_prefix == "" ? lower("${var.project_name}-${var.environment}-${random_string.domain_suffix.result}") : var.user_pool_domain_prefix

  # MFA settings based on configuration string
  sms_mfa_enabled  = contains(var.mfa_methods, "SMS")
  token_mfa_enabled = contains(var.mfa_methods, "SOFTWARE_TOKEN_MFA")
}

# Random suffix for domain prefix if not provided, to help ensure uniqueness
resource "random_string" "domain_suffix" {
  length  = 6
  special = false
  upper   = false
}

# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "user_pool" {
  name = local.user_pool_name

  # Sign-in options
  alias_attributes = var.alias_attributes
  username_attributes = contains(var.alias_attributes, "email") ? ["email"] : null # Allow email sign-in if specified in aliases
  auto_verified_attributes = ["email"] # Automatically verify email

  # Security policies
  password_policy {
    minimum_length    = var.password_policy_minimum_length
    require_lowercase = var.password_policy_require_lowercase
    require_numbers   = var.password_policy_require_numbers
    require_symbols   = var.password_policy_require_symbols
    require_uppercase = var.password_policy_require_uppercase
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration = var.mfa_configuration
  dynamic "software_token_mfa_configuration" {
     # Configure only if enabled
    for_each = local.token_mfa_enabled && var.mfa_configuration != "OFF" ? [1] : []
    content {
      enabled = true
    }
  }
  dynamic "sms_configuration" {
     # Configure only if enabled (Requires SNS setup - external_id and sns_caller_arn must be configured)
    for_each = local.sms_mfa_enabled && var.mfa_configuration != "OFF" ? [1] : []
    content {
      # IMPORTANT: Requires setting up SNS Role and providing ARN here
      # sns_caller_arn = var.cognito_sns_role_arn
      sns_caller_arn = var.cognito_sns_caller_arn # Use the new variable
      external_id    = "${local.user_pool_name}-sms-external" # Example ID
      # sns_region = var.aws_region # Optional: Defaults to User Pool region
    }
  }

  # User attributes (standard)
  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true # Can email be changed after sign-up?
    required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }
  schema {
    name                = "name" # Standard 'name' attribute
    attribute_data_type = "String"
    mutable             = true
    required            = false # Example: not required
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }
  # Add other standard or custom attributes ('custom:attribute_name') as needed

  # Messaging and verification
  admin_create_user_config {
    allow_admin_create_user_only = var.allow_admin_create_user_only # Control self sign-up
    # invite_message_template # Optional
  }
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE"
    email_message         = var.email_verification_message
    email_subject         = var.email_verification_subject
    # sms_message         = "Your verification code is {####}" # Add if using SMS
  }

  # Email Configuration (Using Cognito default or SES)
  # email_configuration {
  #   email_sending_account = "COGNITO_DEFAULT" # Or DEVELOPER to use SES
  #   # source_arn = var.ses_sender_arn # Required if email_sending_account is DEVELOPER
  #   # reply_to_email_address = "reply@example.com" # Optional
  # }

  # Optional: Lambda Triggers (e.g., pre-signup, post-confirmation)
  # lambda_config {
  #   post_confirmation = aws_lambda_function.post_confirmation_lambda.arn
  # }

  tags = merge(local.module_tags, {
    Name = local.user_pool_name
  })
}

# --- Cognito User Pool Client ---
resource "aws_cognito_user_pool_client" "app_client" {
  name            = var.client_name
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = var.generate_client_secret

  # Token Validity Periods
  access_token_validity  = var.access_token_validity_minutes
  id_token_validity      = var.id_token_validity_minutes
  refresh_token_validity = var.refresh_token_validity_days
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # OAuth 2.0 Configuration
  allowed_oauth_flows_user_pool_client = var.allowed_oauth_flows_user_pool_client
  allowed_oauth_flows                  = var.allowed_oauth_flows_user_pool_client ? var.allowed_oauth_flows : null
  allowed_oauth_scopes                 = var.allowed_oauth_flows_user_pool_client ? var.allowed_oauth_scopes : null
  callback_urls                        = var.allowed_oauth_flows_user_pool_client ? var.callback_urls : null
  logout_urls                          = var.allowed_oauth_flows_user_pool_client ? var.logout_urls : null
  supported_identity_providers         = ["COGNITO"] # Add others like Google, Facebook if configured

  # Prevent sign-in with user pool password if only external IdPs used (not typical here)
  # prevent_user_existence_errors = "ENABLED" # Helps prevent user enumeration attacks

  # Specify which standard attributes the client can read and write
  read_attributes  = ["email", "name", "preferred_username", "email_verified", "phone_number", "phone_number_verified"] # Example read access
  write_attributes = ["name", "email", "phone_number"] # Example write access (user can update these)

  explicit_auth_flows = [
    # Recommended flows for modern apps:
    "ALLOW_USER_SRP_AUTH",              # Secure Remote Password protocol
    "ALLOW_REFRESH_TOKEN_AUTH"          # Allow refreshing tokens
    # "ALLOW_ADMIN_USER_PASSWORD_AUTH", # Enable only if needed for admin purposes (less secure)
    # "ALLOW_CUSTOM_AUTH",              # If using custom auth Lambda triggers
    # "ALLOW_USER_PASSWORD_AUTH"        # Basic username/password flow (less secure than SRP)
  ]
}

# --- Cognito User Pool Domain (Optional) ---
# Required for Cognito Hosted UI
resource "aws_cognito_user_pool_domain" "domain" {
  count = var.create_user_pool_domain ? 1 : 0

  domain       = local.domain_prefix # Must be globally unique
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
