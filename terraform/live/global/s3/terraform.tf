terraform {
  required_version = "~> 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # backend "s3" {
  #   key          = "global/s3/terraform.tfstate"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}