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

module "security" {
  source = "../../../modules/security"

  name   = "order-platform-dev"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
}