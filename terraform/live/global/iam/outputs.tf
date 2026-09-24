output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_load_balancer_role_arn" {
  description = "ARN of the ECS infrastructure role for load balancer management"
  value       = aws_iam_role.ecs_load_balancer.arn
}