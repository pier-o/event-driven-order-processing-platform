variable "name" {
  description = "Environment name prefix"
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN containing the RDS credentials"
  type        = string
}

locals {
  region     = data.aws_region.current.region
  account_id = data.aws_caller_identity.current.account_id

  event_bus_arn = "arn:aws:events:${local.region}:${local.account_id}:event-bus/${var.name}-events"
  notifications_queue_arn = "arn:aws:sqs:${local.region}:${local.account_id}:${var.name}-notifications"
  order_notifications_topic_arn = "arn:aws:sns:${local.region}:${local.account_id}:${var.name}-order-notifications"
}