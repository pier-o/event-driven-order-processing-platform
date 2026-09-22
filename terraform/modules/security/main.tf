# ALB
resource "aws_security_group" "alb" {
  name = "${var.name}-alb-sg"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port         = local.port_http
  to_port           = local.port_http
  protocol          = local.protocol_tcp
  cidr_blocks        = local.cidr_all
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port         = local.port_all
  to_port           = local.port_all
  protocol          = local.protocol_all
  cidr_blocks        = local.cidr_all
}

# PostgreSQL
resource "aws_security_group" "postgres" {
  name        = "${var.name}-postgres-sg"
  description = "Allow PostgreSQL from ECS services"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-postgres-sg"
  }
}

resource "aws_security_group_rule" "postgres_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.postgres.id
  source_security_group_id = aws_security_group.ecs.id

  from_port = local.port_postgres
  to_port   = local.port_postgres
  protocol  = local.protocol_tcp
}

resource "aws_security_group_rule" "postgres_egress" {
  type              = "egress"
  security_group_id = aws_security_group.postgres.id

  from_port   = local.port_all
  to_port     = local.port_all
  protocol    = local.protocol_all
  cidr_blocks = local.cidr_all
}

# ECS
resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "Allow application traffic from the ALB and other ECS services"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-ecs-sg"
  }
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb.id

  from_port = local.port_http
  to_port   = local.port_http
  protocol  = local.protocol_tcp
}

resource "aws_security_group_rule" "ecs_from_ecs" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.ecs.id

  from_port = local.port_http
  to_port   = local.port_http
  protocol  = local.protocol_tcp
}

resource "aws_security_group_rule" "ecs_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.ecs.id

  from_port   = local.port_all
  to_port     = local.port_all
  protocol    = local.protocol_all
  cidr_blocks = local.cidr_all
}

# Redis
resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "Allow Redis access from ECS services"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-redis-sg"
  }
}

resource "aws_security_group_rule" "redis_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.redis.id
  source_security_group_id = aws_security_group.ecs.id

  from_port = local.port_redis
  to_port   = local.port_redis
  protocol  = local.protocol_tcp
}

resource "aws_security_group_rule" "redis_egress" {
  type              = "egress"
  security_group_id = aws_security_group.redis.id

  from_port   = local.port_all
  to_port     = local.port_all
  protocol    = local.protocol_all
  cidr_blocks = local.cidr_all
}