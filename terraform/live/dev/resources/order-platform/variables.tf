variable "aws_region" {
  description = "AWS region for this environment"
  type        = string
  default     = "eu-west-1"
}

variable "terraform_state_bucket" {
  description = "AWS bucket name"
  type        = string
  default     = "event-driven-state-ammar-manara"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

variable "notification_email" {
  description = "Email address for order notifications"
  type        = string
  sensitive   = true
}