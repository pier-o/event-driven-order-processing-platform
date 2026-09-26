data "aws_region" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-cluster"

  tags = {
    Name = "${var.name}-cluster"
  }
}

resource "aws_ecs_task_definition" "auth" {
  family                   = "${var.name}-auth"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.auth_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "auth"
      image     = "${var.auth_repository_url}:${var.image_tag}"
      essential = true

      environment = [
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_SECRET_ARN"
          value = var.db_secret_arn
        },
        {
          name  = "REDIS_HOST"
          value = var.redis_host
        },
        {
          name  = "REDIS_PORT"
          value = tostring(var.redis_port)
        },
        {
          name  = "AWS_XRAY_DAEMON_ADDRESS"
          value = "127.0.0.1:2000"
        },
        {
          name  = "AWS_XRAY_TRACING_NAME"
          value = "auth-service"
        },
      ]

      portMappings = [
        {
          name          = "http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = local.protocol_tcp
          appProtocol   = "http"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.auth.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "xray-daemon"
      image     = "public.ecr.aws/xray/aws-xray-daemon:3.6.7"
      essential = true

      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
    }
  ])

  tags = {
    Name = "${var.name}-auth-task"
  }
}

resource "aws_ecs_task_definition" "order" {
  family                   = "${var.name}-order"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.order_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order"
      image     = "${var.order_repository_url}:${var.image_tag}"
      essential = true

      environment = [
        {
          name  = "EVENT_BUS_NAME"
          value = aws_cloudwatch_event_bus.main.name
        },
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_SECRET_ARN"
          value = var.db_secret_arn
        },
        {
          name  = "REDIS_HOST"
          value = var.redis_host
        },
        {
          name  = "REDIS_PORT"
          value = tostring(var.redis_port)
        },
        {
          name  = "AWS_XRAY_DAEMON_ADDRESS"
          value = "127.0.0.1:2000"
        },
        {
          name  = "AWS_XRAY_TRACING_NAME"
          value = "order-service"
        },
      ]

      portMappings = [
        {
          name          = "http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = local.protocol_tcp
          appProtocol   = "http"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.order.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "xray-daemon"
      image     = "public.ecr.aws/xray/aws-xray-daemon:3.6.7"
      essential = true

      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
    }
  ])

  tags = {
    Name = "${var.name}-order-task"
  }
}

resource "aws_ecs_task_definition" "notify" {
  family                   = "${var.name}-notify"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.notify_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "notify"
      image     = "${var.notify_repository_url}:${var.image_tag}"
      essential = true

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = aws_sqs_queue.notifications.url
        },
        {
          name  = "SNS_TOPIC_ARN"
          value = aws_sns_topic.order_notifications.arn
        },
        {
          name  = "AWS_XRAY_DAEMON_ADDRESS"
          value = "127.0.0.1:2000"
        },
        {
          name  = "AWS_XRAY_TRACING_NAME"
          value = "notify-service"
        },
      ]

      portMappings = [
        {
          name          = "http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = local.protocol_tcp
          appProtocol   = "http"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.notify.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "xray-daemon"
      image     = "public.ecr.aws/xray/aws-xray-daemon:3.6.7"
      essential = true

      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
    }
  ])

  tags = {
    Name = "${var.name}-notify-task"
  }
}

resource "aws_ecs_service" "auth" {
  name            = "${var.name}-auth"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.auth.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_configuration {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = 5
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.main.arn

    service {
      port_name      = "http"
      discovery_name = "auth"

      client_alias {
        dns_name = "auth"
        port     = 80
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth.arn
    container_name   = "auth"
    container_port   = var.container_port

    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.auth_green.arn
      production_listener_rule   = aws_lb_listener_rule.auth.arn
      role_arn                   = var.ecs_load_balancer_role_arn
    }
  }

  tags = {
    Name = "${var.name}-auth-service"
  }
}

resource "aws_ecs_service" "order" {
  name            = "${var.name}-order"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_configuration {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = 5
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.main.arn

    service {
      port_name      = "http"
      discovery_name = "order"

      client_alias {
        dns_name = "order"
        port     = 80
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.order.arn
    container_name   = "order"
    container_port   = var.container_port

    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.order_green.arn
      production_listener_rule   = aws_lb_listener_rule.order.arn
      role_arn                   = var.ecs_load_balancer_role_arn
    }
  }

  tags = {
    Name = "${var.name}-order-service"
  }
}

resource "aws_ecs_service" "notify" {
  name            = "${var.name}-notify"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.notify.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_configuration {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = 5
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_private_dns_namespace.main.arn

    service {
      port_name      = "http"
      discovery_name = "notify"

      client_alias {
        dns_name = "notify"
        port     = 80
      }
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.notify.arn
    container_name   = "notify"
    container_port   = var.container_port

    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.notify_green.arn
      production_listener_rule   = aws_lb_listener_rule.notify.arn
      role_arn                   = var.ecs_load_balancer_role_arn
    }
  }

  tags = {
    Name = "${var.name}-notify-service"
  }
}