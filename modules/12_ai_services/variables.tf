# -----------------------------------------------------------------------------
# Input variables for the ai_services module (primarily HealthLake)
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "A name for the project to prefix resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

# --- HealthLake Configuration ---

variable "create_healthlake_datastore" {
  description = "Set to true to create an Amazon HealthLake FHIR Datastore"
  type        = bool
  default     = true # Based on diagram including HealthLake
}

variable "healthlake_datastore_name" {
  description = "Name for the HealthLake FHIR Datastore (defaults to project-env-fhir-store)"
  type        = string
  default     = "" # If empty, will be constructed
}

variable "healthlake_datastore_type_version" {
  description = "FHIR version for the HealthLake datastore (e.g., R4)"
  type        = string
  default     = "R4"
}

variable "healthlake_sse_kms_key_arn" {
  description = "ARN of the customer-managed KMS key for HealthLake SSE. If null, an AWS owned key is used."
  type        = string
  default     = null # Uses AWS owned key by default
}

variable "healthlake_preload_data_config" {
  description = "Configuration block for preloading data. `preload_data_type` can be SYNTHEA."
  type = object({
    preload_data_type = string
  })
  default = null # No preloading by default
  # Example: { preload_data_type = "SYNTHEA" }
}

# --- Tags ---
variable "common_tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}