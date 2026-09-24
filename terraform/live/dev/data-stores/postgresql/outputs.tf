output "db_endpoint" {
  value = module.postgresql.db_endpoint
}

output "db_port" {
  value = module.postgresql.db_port
}

output "db_name" {
  value = module.postgresql.db_name
}

output "master_user_secret_arn" {
  value     = module.postgresql.master_user_secret_arn
  sensitive = true
}