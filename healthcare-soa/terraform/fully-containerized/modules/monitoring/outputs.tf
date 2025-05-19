output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cpu_alarms" {
  description = "Map of CPU alarms for each service"
  value       = { for name, alarm in aws_cloudwatch_metric_alarm.service_cpu : name => alarm.arn }
}

output "memory_alarms" {
  description = "Map of memory alarms for each service"
  value       = { for name, alarm in aws_cloudwatch_metric_alarm.service_memory : name => alarm.arn }
}
