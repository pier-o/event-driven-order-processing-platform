output "db_endpoint" {
  description = "The endpoint of the PostgreSQL database"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "The PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "The name of the PostgreSQL database"
  value       = aws_db_instance.postgres.db_name
}

output "db_security_group_id" {
  description = "The PostgreSQL security group ID"
  value       = aws_security_group.postgres.id
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}