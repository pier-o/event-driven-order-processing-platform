variable "name" {
  description = "Name prefix for the application resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

locals {
  port_postgres = 5432
  port_redis    = 6379
  port_http     = 80
  port_all      = 0

  protocol_tcp  = "tcp"
  protocol_http = "HTTP"
  protocol_all  = "-1"

  target_ip = "ip"
  cidr_all  = ["0.0.0.0/0"]
}