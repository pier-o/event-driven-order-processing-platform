data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "auth_task" {
  name = "${var.name}-auth-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.name}-auth-task-role"
  }
}

resource "aws_iam_role" "order_task" {
  name = "${var.name}-order-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.name}-order-task-role"
  }
}

resource "aws_iam_role" "notify_task" {
  name = "${var.name}-notify-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.name}-notify-task-role"
  }
}

resource "aws_iam_role_policy" "order_eventbridge" {
  name = "${var.name}-order-eventbridge"
  role = aws_iam_role.order_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "events:PutEvents"
        ]

        Resource = local.event_bus_arn
      },
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.db_secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "notify_sqs" {
  name = "${var.name}-notify-sqs"
  role = aws_iam_role.notify_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = local.notifications_queue_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "notify_sns" {
  name = "${var.name}-notify-sns"
  role = aws_iam_role.notify_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = local.order_notifications_topic_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "auth_secretsmanager" {
  name = "${var.name}-auth-secretsmanager"
  role = aws_iam_role.auth_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = var.db_secret_arn
      }
    ]
  })
}