provider "aws" {
  region = "eu-west-1"
}

module "networking" {
  source = "../../../modules/networking"

  vpc_name = "order-platform-dev"
  vpc_cidr = "192.168.0.0/16"
}