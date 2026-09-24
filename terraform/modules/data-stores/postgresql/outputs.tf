output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "RDS PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing the RDS master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}