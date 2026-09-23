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


module "redis" {
  source = "../../../../modules/data-stores/redis"

  name = "order-platform-dev"

  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

  redis_security_group_id = data.terraform_remote_state.security.outputs.redis_security_group_id
}