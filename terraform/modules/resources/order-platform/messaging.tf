resource "aws_sqs_queue" "notifications_dlq" {
  name = "${var.name}-notifications-dlq"

  tags = {
    Name = "${var.name}-notifications-dlq"
  }
}

resource "aws_sqs_queue" "notifications" {
  name = "${var.name}-notifications"

  visibility_timeout_seconds = 60
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name = "${var.name}-notifications"
  }
}

resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.name}-events"

  tags = {
    Name = "${var.name}-events"
  }
}

resource "aws_cloudwatch_event_rule" "order_created" {
  name           = "${var.name}-order-created"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source = ["order-service"]
    "detail-type" = ["OrderCreated"]
  })
}

resource "aws_cloudwatch_event_target" "notifications_queue" {
  rule           = aws_cloudwatch_event_rule.order_created.name
  event_bus_name = aws_cloudwatch_event_bus.main.name

  target_id = "NotificationsQueue"
  arn       = aws_sqs_queue.notifications.arn
}

data "aws_iam_policy_document" "notifications_queue_policy" {
  statement {
    sid    = "AllowEventBridge"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.notifications.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.order_created.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id
  policy    = data.aws_iam_policy_document.notifications_queue_policy.json
}

resource "aws_sns_topic" "order_notifications" {
  name = "${var.name}-order-notifications"

  tags = {
    Name = "${var.name}-order-notifications"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.order_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}