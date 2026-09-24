resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "myapp.local"
  description = "Private service discovery namespace for ${var.name}"
  vpc         = var.vpc_id

  tags = {
    Name = "${var.name}-namespace"
  }
}
