variable "name" {
  description = "Name"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "redis_security_group_id" {
  description = "Redis Security Group ID"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

locals {
  redis_port   = 6379
  port_all     = 0
  protocol_tcp = "tcp"
  protocol_all = "-1"
  cidr_all     = ["0.0.0.0/0"]
}