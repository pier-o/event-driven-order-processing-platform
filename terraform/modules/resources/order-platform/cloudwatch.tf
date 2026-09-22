resource "aws_cloudwatch_log_group" "auth" {
  name              = "/ecs/${var.name}/auth"
  retention_in_days = 7

  tags = {
    Name = "${var.name}-auth-logs"
  }
}

resource "aws_cloudwatch_log_group" "order" {
  name              = "/ecs/${var.name}/order"
  retention_in_days = 7

  tags = {
    Name = "${var.name}-order-logs"
  }
}

resource "aws_cloudwatch_log_group" "notify" {
  name              = "/ecs/${var.name}/notify"
  retention_in_days = 7

  tags = {
    Name = "${var.name}-notify-logs"
  }
}