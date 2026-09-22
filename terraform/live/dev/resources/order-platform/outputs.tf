output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.order_platform.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.order_platform.alb_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.order_platform.ecs_cluster_name
}

output "auth_service_name" {
  description = "Name of the Auth ECS service"
  value       = module.order_platform.auth_service_name
}

output "order_service_name" {
  description = "Name of the Orders ECS service"
  value       = module.order_platform.order_service_name
}

output "notify_service_name" {
  description = "Name of the Notifications ECS service"
  value       = module.order_platform.notify_service_name
}