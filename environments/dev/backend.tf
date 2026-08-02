# -----------------------------------------------------------------------------
# Terraform Backend
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket       = "zhu-api-platform-dev-tfstate"
    key          = "api-platform/dev/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}