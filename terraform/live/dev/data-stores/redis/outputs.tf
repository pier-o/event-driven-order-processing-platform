output "redis_host" {
  description = "Redis host"
  value       = module.redis.redis_host
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.redis_port
}