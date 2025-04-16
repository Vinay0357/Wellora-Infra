# -----------------------------------------------------------------------------
# Outputs from the load_balancing module
# -----------------------------------------------------------------------------

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the Application Load Balancer (useful for Route 53 alias records)"
  value       = aws_lb.alb.zone_id
}

output "target_group_arn" {
  description = "The ARN of the default application target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "target_group_name" {
  description = "The Name of the default application target group"
  value       = aws_lb_target_group.app_tg.name
}

output "http_listener_arn" {
  description = "The ARN of the HTTP listener (if created)"
  value       = length(aws_lb_listener.http_listener) > 0 ? aws_lb_listener.http_listener[0].arn : null
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener (if created)"
  value       = length(aws_lb_listener.https_listener) > 0 ? aws_lb_listener.https_listener[0].arn : null
}
