output "kafka_ui_url" {
  description = "The URL of the Kafka-UI interface"
  value       = "http://${aws_lb.kafka_ui.dns_name}"
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.kafka_ui.dns_name
}

output "task_definition_arn" {
  description = "ARN of the Kafka-UI task definition"
  value       = aws_ecs_task_definition.kafka_ui.arn
}

output "service_name" {
  description = "Name of the Kafka-UI ECS service"
  value       = aws_ecs_service.kafka_ui.name
}
