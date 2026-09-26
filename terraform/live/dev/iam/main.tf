provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "postgresql" {
  backend = "s3"

  config = {
    bucket = var.terraform_state_bucket
    key    = "dev/data-stores/postgresql/terraform.tfstate"
    region = var.aws_region
  }
}

module "iam" {
  source = "../../../modules/iam"

  name          = "order-platform-dev"
  db_secret_arn = data.terraform_remote_state.postgresql.outputs.master_user_secret_arn
}