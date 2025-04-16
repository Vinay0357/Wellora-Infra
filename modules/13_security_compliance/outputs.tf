# -----------------------------------------------------------------------------
# Outputs from the security_compliance module
# -----------------------------------------------------------------------------

output "guardduty_detector_id" {
  description = "The ID of the GuardDuty detector"
  value       = length(aws_guardduty_detector.detector) > 0 ? aws_guardduty_detector.detector[0].id : null
}

output "config_recorder_name" {
  description = "The name of the AWS Config configuration recorder"
  value       = length(aws_config_configuration_recorder.recorder) > 0 ? aws_config_configuration_recorder.recorder[0].name : null
}

output "cloudtrail_arn" {
  description = "The ARN of the CloudTrail trail"
  value       = length(aws_cloudtrail.trail) > 0 ? aws_cloudtrail.trail[0].arn : null
}

output "cloudtrail_cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch Log Group for CloudTrail events"
  value       = length(aws_cloudwatch_log_group.cloudtrail_log_group) > 0 ? aws_cloudwatch_log_group.cloudtrail_log_group[0].arn : null
}

output "security_hub_account_enabled" {
  description = "Indicates if Security Hub was enabled for the account in this region"
  value       = length(aws_securityhub_account.sh_account) > 0 ? true : false
}

output "inspector_enabled_resource_types" {
  description = "List of resource types enabled for Inspector v2 scanning"
  value       = length(aws_inspector2_enabler.inspector_enabler) > 0 ? aws_inspector2_enabler.inspector_enabler[0].resource_types : []
}

output "macie_account_id" {
  description = "The AWS account ID where Macie was enabled (should match current account)"
  value       = length(aws_macie2_account.macie_account) > 0 ? aws_macie2_account.macie_account[0].id : null
}
