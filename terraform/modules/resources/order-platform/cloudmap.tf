resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "myapp.local"
  description = "Private service discovery namespace for ${var.name}"
  vpc         = var.vpc_id

  tags = {
    Name = "${var.name}-namespace"
  }
}

resource "aws_service_discovery_service" "auth" {
  name = "auth"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${var.name}-auth-discovery"
  }
}

resource "aws_service_discovery_service" "order" {
  name = "order"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${var.name}-order-discovery"
  }
}

resource "aws_service_discovery_service" "notify" {
  name = "notify"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${var.name}-notify-discovery"
  }
}