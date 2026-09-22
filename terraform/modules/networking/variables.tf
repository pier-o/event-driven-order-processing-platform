variable "vpc_name" {
  description = "The VPC Name"
  type = string
}

variable "vpc_cidr" {
  description = "The VPC CIDR block"
  type = string
}

# Locals
locals {
  any_ip      = "0.0.0.0/0"
}