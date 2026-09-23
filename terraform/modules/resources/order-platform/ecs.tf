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
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "auth"
      image     = "${var.auth_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = local.protocol_tcp
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
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order"
      image     = "${var.order_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = local.protocol_tcp
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
  task_role_arn      = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "notify"
      image     = "${var.notify_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = local.protocol_tcp
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
    strategy                = "BLUE_GREEN"
    bake_time_in_minutes    = 5
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.auth.arn
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
  launch_type      = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_configuration {
    strategy                = "BLUE_GREEN"
    bake_time_in_minutes    = 5
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order.arn
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
  launch_type      = "FARGATE"
  
  deployment_controller {
  type = "ECS"
  }

  deployment_configuration {
    strategy                = "BLUE_GREEN"
    bake_time_in_minutes    = 5
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }
  
  service_registries {
    registry_arn = aws_service_discovery_service.notify.arn
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