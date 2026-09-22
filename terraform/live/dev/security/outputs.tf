output "alb_security_group_id" {
  value = module.security.alb_security_group_id
}

output "ecs_security_group_id" {
  value = module.security.ecs_security_group_id
}

output "postgres_security_group_id" {
  value = module.security.postgres_security_group_id
}

output "redis_security_group_id" {
  value = module.security.redis_security_group_id
}