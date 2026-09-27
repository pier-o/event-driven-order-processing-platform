provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_account_setting" "blob_mounting" {
  name  = "BLOB_MOUNTING"
  value = "ENABLED"
}

resource "aws_ecr_repository" "auth" {
  name                 = "order-platform/auth"
  image_tag_mutability = "IMMUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "order-platform-authentications"
  }
}

resource "aws_ecr_repository" "order" {
  name                 = "order-platform/order"
  image_tag_mutability = "IMMUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "order-platform-orders"
  }
}

resource "aws_ecr_repository" "notify" {
  name                 = "order-platform/notify"
  image_tag_mutability = "IMMUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "order-platform-notifications"
  }
}