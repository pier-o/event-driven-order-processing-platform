# ECS
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "auth_service_name" {
  description = "Name of the Auth ECS service"
  value       = aws_ecs_service.auth.name
}

output "order_service_name" {
  description = "Name of the Orders ECS service"
  value       = aws_ecs_service.order.name
}

output "notify_service_name" {
  description = "Name of the Notifications ECS service"
  value       = aws_ecs_service.notify.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# Cloud Map
output "cloud_map_namespace_id" {
  description = "ID of the Cloud Map private DNS namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "auth_service_discovery_name" {
  description = "DNS name of the Auth service"
  value       = "auth.${aws_service_discovery_private_dns_namespace.main.name}"
}

output "order_service_discovery_name" {
  description = "DNS name of the Orders service"
  value       = "order.${aws_service_discovery_private_dns_namespace.main.name}"
}

output "notify_service_discovery_name" {
  description = "DNS name of the Notifications service"
  value       = "notify.${aws_service_discovery_private_dns_namespace.main.name}"
}

# Secret Manager
output "application_secret_arn" {
  description = "ARN of the application Secrets Manager secret"
  value       = aws_secretsmanager_secret.application.arn
}

# Messaging
output "event_bus_arn" {
  description = "ARN of the application EventBridge event bus"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "notifications_queue_url" {
  description = "URL of the Notifications SQS queue"
  value       = aws_sqs_queue.notifications.url
}

output "notifications_queue_arn" {
  description = "ARN of the Notifications SQS queue"
  value       = aws_sqs_queue.notifications.arn
}

output "order_notifications_topic_arn" {
  description = "ARN of the SNS topic used for order notifications"
  value       = aws_sns_topic.order_notifications.arn
}