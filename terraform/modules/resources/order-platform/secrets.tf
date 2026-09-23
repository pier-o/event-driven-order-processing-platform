resource "aws_secretsmanager_secret" "application" {
  name        = "${var.name}/application"
  description = "Application secrets for ${var.name}"

  tags = {
    Name = "${var.name}-application-secret"
  }
}