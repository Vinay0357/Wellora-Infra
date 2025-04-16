# -----------------------------------------------------------------------------
# Outputs from the messaging module
# -----------------------------------------------------------------------------

# --- SES Outputs ---
output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = length(aws_ses_domain_identity.domain) > 0 ? aws_ses_domain_identity.domain[0].arn : null
}

output "ses_domain_identity_verification_token" {
  description = "The TXT record value required to verify domain ownership in DNS"
  value       = length(aws_ses_domain_identity.domain) > 0 ? aws_ses_domain_identity.domain[0].verification_token : null
  # User needs to create a TXT record in DNS: _amazonses.<your_domain> VALUE "<token>"
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for the SES domain identity. CNAME records need to be created in DNS for these."
  value       = length(aws_ses_domain_dkim.dkim) > 0 ? aws_ses_domain_dkim.dkim[0].dkim_tokens : null
  # User needs to create CNAME records in DNS: <token>._domainkey.<your_domain> CNAME <token>.dkim.amazonses.com
}

output "ses_configuration_set_name" {
  description = "Name of the created SES Configuration Set"
  value       = length(aws_ses_configuration_set.config_set) > 0 ? aws_ses_configuration_set.config_set[0].name : null
}

# --- SNS Outputs ---
output "sns_topic_arns" {
  description = "Map of logical topic names to SNS topic ARNs"
  value       = { for k, topic in aws_sns_topic.topics : k => topic.arn }
}

output "sns_topic_names_map" {
  description = "Map of logical topic names to actual SNS topic names"
  value       = { for k, topic in aws_sns_topic.topics : k => topic.name }
}
