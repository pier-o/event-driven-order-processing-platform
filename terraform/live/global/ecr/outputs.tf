output "auth_repository_url" {
  description = "ECR repository URL for the Authentications service"
  value       = aws_ecr_repository.auth.repository_url
}

output "orders_repository_url" {
  description = "ECR repository URL for the Orders service"
  value       = aws_ecr_repository.order.repository_url
}

output "notifications_repository_url" {
  description = "ECR repository URL for the Notifications service"
  value       = aws_ecr_repository.notify.repository_url
}