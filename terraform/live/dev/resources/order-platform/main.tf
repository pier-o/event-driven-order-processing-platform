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

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "global/iam/terraform.tfstate"
    region = var.aws_region
  }
}

module "order_platform" {
  source = "../../../../modules/resources/order-platform"
  
  name = "order-platform-dev"

  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.networking.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  
  alb_security_group_id = data.terraform_remote_state.security.outputs.alb_security_group_id
  ecs_security_group_id = data.terraform_remote_state.security.outputs.ecs_security_group_id

  auth_repository_url = data.terraform_remote_state.ecr.outputs.auth_repository_url
  order_repository_url =  data.terraform_remote_state.ecr.outputs.orders_repository_url
  notify_repository_url = data.terraform_remote_state.ecr.outputs.notifications_repository_url

  execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_execution_role_arn
  ecs_load_balancer_role_arn =  data.terraform_remote_state.iam.outputs.ecs_load_balancer_role_arn
  task_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_role_arn


  image_tag = var.image_tag
}