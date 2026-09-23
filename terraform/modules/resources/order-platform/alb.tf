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

resource "aws_lb_target_group" "auth" {
  name        = "${var.name}-auth-tg"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/auth/health"
    protocol            = local.protocol_http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "auth_green" {
  name        = "${var.name}-auth-green"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/auth/health"
    protocol            = local.protocol_http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "order" {
  name        = "${var.name}-order-tg"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id
  
  health_check {
    path                = "/api/order/health"
    protocol            = local.protocol_http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "order_green" {
  name        = "${var.name}-order-green"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/order/health"
    protocol            = local.protocol_http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "notify" {
  name        = "${var.name}-notify-tg"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id
  
  health_check {
    path                = "/api/notify/health"
    protocol            = local.protocol_http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "notify_green" {
  name        = "${var.name}-notify-green"
  target_type = local.target_ip
  port        = local.port_http
  protocol    = local.protocol_http
  vpc_id      = var.vpc_id

  health_check {
    path                = "/api/notify/health"
    protocol            = local.protocol_http
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port = local.port_http
  protocol = local.protocol_http

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"service\":\"order-platform\",\"status\":\"ok\"}"
      status_code  = 200
    }
  }
}

resource "aws_lb_listener_rule" "auth" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type             = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.auth.arn
        weight = 100
      }

      target_group {
        arn = aws_lb_target_group.auth_green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/auth", "/api/auth/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.order.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.order_green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/order", "/api/order/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}

resource "aws_lb_listener_rule" "notify" {
  listener_arn = aws_lb_listener.http.arn

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.notify.arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.notify_green.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/notify", "/api/notify/*"]
    }
  }

  lifecycle {
    ignore_changes = [action]
  }
}