output "alb_security_group_id" {
  description = "The ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "The ECS security group ID"
  value       = aws_security_group.ecs.id
}

output "postgres_security_group_id" {
  description = "The PostgreSQL security group ID"
  value       = aws_security_group.postgres.id
}

output "redis_security_group_id" {
  description = "The Redis security group ID"
  value       = aws_security_group.redis.id
}