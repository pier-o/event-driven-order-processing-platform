variable "name" {
  description = "Name prefix for the application resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"  
  type = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

# ALB
variable "alb_security_group_id" {
  description = "The ID of the ALB"
  type = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = false
}

# ECS
variable "ecs_security_group_id" {
  description = "The ECS security group ID"
  type        = string
}

variable "ecs_load_balancer_role_arn" {
  description = "ARN of the ECS infrastructure role for load balancer management"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  type        = string
}

variable "auth_task_role_arn" {
  description = "ARN of the Auth ECS task role"
  type        = string
}

variable "order_task_role_arn" {
  description = "ARN of the Orders ECS task role"
  type        = string
}

variable "notify_task_role_arn" {
  description = "ARN of the Notifications ECS task role"
  type        = string
}

variable "auth_repository_url" {
  description = "ECR repository URL for the Auth service"
  type        = string
}

variable "order_repository_url" {
  description = "ECR repository URL for the Orders service"
  type        = string
}

variable "notify_repository_url" {
  description = "ECR repository URL for the Notifications service"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the application containers"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "CPU units for each Fargate task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory in MiB for each Fargate task"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of Fargate tasks for each service"
  type        = number
  default     = 1
}

# DB
variable "db_host" {
  description = "PostgreSQL RDS endpoint"
  type        = string
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN containing the RDS credentials"
  type        = string
}

#Redis
variable "redis_host" {
  description = "Redis host endpoint"
  type        = string
}

variable "redis_port" {
  description = "redis port"
  type        = number
}

locals {
  port_http    = 80
  port_all     = 0

  protocol_tcp   = "tcp"
  protocol_http  = "HTTP"
  protocol_all   = "-1"

  target_ip = "ip"
  cidr_all  = ["0.0.0.0/0"]
}