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