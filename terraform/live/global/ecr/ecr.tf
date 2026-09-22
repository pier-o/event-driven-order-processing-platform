resource "aws_ecr_repository" "auth" {
  name                 = "order-platform/auth"
  image_tag_mutability = "IMMUTABLE"

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

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "order-platform-notifications"
  }
}