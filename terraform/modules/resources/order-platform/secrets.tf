resource "aws_secretsmanager_secret" "application" {
  name        = "${var.name}/application"
  description = "Application secrets for ${var.name}"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.name}-application-secret"
  }
}