# Terraform requirements
terraform {

  required_version = ">= 1.8.3, < 2.0.0"

  required_providers {

    aws = {

      source = "hashicorp/aws"

      version = "=5.49"
    }
  }
}

# AWS provider
provider "aws" {

  profile = "prd"

  region = "ap-northeast-1"

  default_tags {

    tags = {

      cGroup = "prd-test2"
    }
  }
}

# Remote state backend
terraform {

  backend "s3" {

    bucket = "zhu-terraform-state-bucket"

    key = "prd/terraform.tfstate"

    region = "ap-northeast-1"

    profile = "prd"

    encrypt = true

  }
}
