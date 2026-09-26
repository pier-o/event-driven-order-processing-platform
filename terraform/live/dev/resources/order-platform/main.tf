provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "dev/networking/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "dev/security/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "global/ecr/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "global_iam" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "global/iam/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "dev_iam" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "dev/iam/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "postgresql" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "dev/data-stores/postgresql/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "redis" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "dev/data-stores/redis/terraform.tfstate"
    region = var.aws_region
  }
}

module "order_platform" {
  source = "../../../../modules/resources/order-platform"

  name = "order-platform-dev"

  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

  alb_security_group_id = data.terraform_remote_state.security.outputs.alb_security_group_id
  ecs_security_group_id = data.terraform_remote_state.security.outputs.ecs_security_group_id

  auth_repository_url   = data.terraform_remote_state.ecr.outputs.auth_repository_url
  order_repository_url  = data.terraform_remote_state.ecr.outputs.orders_repository_url
  notify_repository_url = data.terraform_remote_state.ecr.outputs.notifications_repository_url

  ecs_load_balancer_role_arn = data.terraform_remote_state.global_iam.outputs.ecs_load_balancer_role_arn
  execution_role_arn         = data.terraform_remote_state.global_iam.outputs.ecs_execution_role_arn
  auth_task_role_arn         = data.terraform_remote_state.dev_iam.outputs.auth_task_role_arn
  order_task_role_arn        = data.terraform_remote_state.dev_iam.outputs.order_task_role_arn
  notify_task_role_arn       = data.terraform_remote_state.dev_iam.outputs.notify_task_role_arn

  image_tag = var.image_tag

  db_host       = data.terraform_remote_state.postgresql.outputs.db_host
  db_port       = data.terraform_remote_state.postgresql.outputs.db_port
  db_name       = data.terraform_remote_state.postgresql.outputs.db_name
  db_secret_arn = data.terraform_remote_state.postgresql.outputs.master_user_secret_arn

  redis_host = data.terraform_remote_state.redis.outputs.redis_host
  redis_port = data.terraform_remote_state.redis.outputs.redis_port

  notification_email = var.notification_email
}