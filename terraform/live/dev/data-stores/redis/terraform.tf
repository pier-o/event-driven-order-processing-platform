terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key          = "dev/data-stores/redis/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
