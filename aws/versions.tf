terraform {
  required_version = ">= 1.10.0"
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "oficina-tech-challenge"
      Phase     = "3"
      ManagedBy = "terraform"
    }
  }
}
