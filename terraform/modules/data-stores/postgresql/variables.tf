variable "name" {
  description = "Name"
  type        = string
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "db_name" {
  description = "The Database Name"
  type        = string
}

variable "db_username" {
  description = "The DB username"
  type        = string
  sensitive   = true
}

variable "postgres_security_group_id" {
  description = "Postgres Security Group ID"
  type        = string
}

variable "instance_class" {
  description = "Instance Class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The Storage of the DB (e.g., 10G)"
  type        = number
  default     = 10
}

locals {
  postgres_port = 5432
  any_port      = 0

  protocol_tcp = "tcp"
  protocol_all = "-1"

  cidr_all = ["0.0.0.0/0"]
}