resource "aws_lb" "main" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false

  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]

  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_target_group" "notify" {
  name        = "${var.name}-notify-tg"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group" "order" {
  name        = "${var.name}-order-tg"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group" "auth" {
  name        = "${var.name}-auth-tg"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = local.port_http
  protocol = local.protocol_http

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "notify" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notify.arn
  }

  condition {
    path_pattern {
      values = ["/api/notify/*"]
    }
  }
}

resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order.arn
  }

  condition {
    path_pattern {
      values = ["/api/order/*"]
    }
  }
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth.arn
  }

  condition {
    path_pattern {
      values = ["/api/auth/*"]
    }
  }
}