output "auth_task_role_arn" {
  description = "ARN of the Auth ECS task role"
  value       = aws_iam_role.auth_task.arn
}

output "order_task_role_arn" {
  description = "ARN of the Orders ECS task role"
  value       = aws_iam_role.order_task.arn
}

output "notify_task_role_arn" {
  description = "ARN of the Notifications ECS task role"
  value       = aws_iam_role.notify_task.arn
}