# -----------------------------------------------------------------------------
# Input variables for the authentication module (Cognito)
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

# --- User Pool Configuration ---

variable "user_pool_name" {
  description = "Name for the Cognito User Pool"
  type        = string
  default     = "" # If empty, will be constructed like project-env-users
}

variable "allow_admin_create_user_only" {
  description = "Set to true to prevent self-service sign-up. Users must be created by an administrator."
  type        = bool
  default     = false # Allow self-sign up by default
}

variable "mfa_configuration" {
  description = "Multi-Factor Authentication configuration (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"
  validation {
    condition     = contains(["OFF", "ON", "OPTIONAL"], var.mfa_configuration)
    error_message = "Allowed MFA configurations are OFF, ON, OPTIONAL."
  }
}

variable "mfa_methods" {
  description = "List of MFA methods (SMS, SOFTWARE_TOKEN_MFA for TOTP)"
  type        = list(string)
  default     = ["SOFTWARE_TOKEN_MFA"] # Default to authenticator app
}

variable "email_verification_subject" {
  description = "Subject line for the verification email"
  type        = string
  default     = "Verify your email for Wellora"
}

variable "email_verification_message" {
  description = "Body of the verification email. Must include {username} and {####} placeholders."
  type        = string
  default     = "Welcome to Wellora! Your username is {username} and your verification code is {####}"
}

variable "password_policy_minimum_length" {
  description = "Minimum password length"
  type        = number
  default     = 8
}

variable "password_policy_require_lowercase" {
  description = "Require lowercase letters in password"
  type        = bool
  default     = true
}

variable "password_policy_require_uppercase" {
  description = "Require uppercase letters in password"
  type        = bool
  default     = true
}

variable "password_policy_require_numbers" {
  description = "Require numbers in password"
  type        = bool
  default     = true
}

variable "password_policy_require_symbols" {
  description = "Require symbols in password"
  type        = bool
  default     = true
}

variable "alias_attributes" {
  description = "Attributes that can be used as aliases for sign-in (e.g., email, phone_number, preferred_username)"
  type        = list(string)
  default     = ["email", "preferred_username"] # Allow sign in with email or username
}

# --- User Pool Client Configuration ---

variable "client_name" {
  description = "Name for the Cognito User Pool Client"
  type        = string
  default     = "webapp" # Client for the main web application
}

variable "generate_client_secret" {
  description = "Generate a client secret for this app client (needed for confidential clients, e.g., server-side using authorization code flow)"
  type        = bool
  default     = false # Typically false for public clients like SPAs using implicit or code flow with PKCE
}

variable "allowed_oauth_flows" {
  description = "List of allowed OAuth flows (code, implicit, client_credentials)"
  type        = list(string)
  default     = ["code"] # Authorization code grant flow (recommended with PKCE for SPAs)
}

variable "allowed_oauth_scopes" {
  description = "List of allowed OAuth scopes"
  type        = list(string)
  default     = ["openid", "email", "profile", "phone"]
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the application after successful sign-in"
  type        = list(string)
  default     = ["http://localhost:3000/callback"] # Replace with actual app URLs
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the application"
  type        = list(string)
  default     = ["http://localhost:3000/logout"] # Replace with actual app URLs
}

variable "access_token_validity_minutes" {
  description = "Access token validity period in minutes"
  type        = number
  default     = 60 # 1 hour
}

variable "id_token_validity_minutes" {
  description = "ID token validity period in minutes"
  type        = number
  default     = 60 # 1 hour
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity period in days"
  type        = number
  default     = 30
}

variable "allowed_oauth_flows_user_pool_client" {
  description = "Should the specified OAuth flows be enabled for the client?"
  type        = bool
  default     = true # Enable OAuth flows
}

# --- Domain ---
variable "create_user_pool_domain" {
  description = "Set to true to create a Cognito User Pool domain (required for hosted UI)"
  type        = bool
  default     = false # Typically false if integrating directly with frontend SDKs
}

variable "user_pool_domain_prefix" {
  description = "Prefix for the Cognito User Pool domain (must be globally unique)"
  type        = string
  default     = "" # If empty and create_user_pool_domain is true, will construct like project-env
}

variable "cognito_sns_caller_arn" {
   description = "ARN of the IAM Role that Cognito assumes to publish SNS messages for SMS MFA. Required if SMS MFA is enabled."
   type        = string
   default     = null # Must be provided if using SMS MFA
 }


# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}
