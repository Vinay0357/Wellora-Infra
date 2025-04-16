# -----------------------------------------------------------------------------
# Outputs from the ai_services module
# -----------------------------------------------------------------------------

output "healthlake_datastore_id" {
  description = "The ID of the HealthLake FHIR Datastore"
  value       = length(aws_healthlake_fhir_datastore.datastore) > 0 ? aws_healthlake_fhir_datastore.datastore[0].id : null
}

output "healthlake_datastore_arn" {
  description = "The ARN of the HealthLake FHIR Datastore"
  value       = length(aws_healthlake_fhir_datastore.datastore) > 0 ? aws_healthlake_fhir_datastore.datastore[0].arn : null
}

output "healthlake_datastore_endpoint" {
  description = "The endpoint for the HealthLake FHIR Datastore"
  value       = length(aws_healthlake_fhir_datastore.datastore) > 0 ? aws_healthlake_fhir_datastore.datastore[0].datastore_endpoint : null
}
