provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "../../../modules/networking"

  vpc_name = "order-platform-dev"
  vpc_cidr = "192.168.0.0/16"
}