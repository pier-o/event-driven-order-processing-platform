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

module "postgresql" {
  source = "../../../../modules/data-stores/postgresql"

  name = "order-platform-dev"
  db_name     = "order_platform"
  db_username = "order_platform_admin"
  
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids

  postgres_security_group_id = data.terraform_remote_state.security.outputs.postgres_security_group_id
}