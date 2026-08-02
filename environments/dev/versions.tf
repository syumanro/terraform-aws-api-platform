# -----------------------------------------------------------------------------
# Terraform and provider version requirements
# -----------------------------------------------------------------------------

terraform {
  # Required Terraform CLI version
  required_version = ">= 1.5.0"

  # Required providers
  required_providers {
    aws = {
      source = "hashicorp/aws"

      # AWS Provider version
      version = "~> 6.0"
    }
  }
}