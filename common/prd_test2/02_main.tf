terraform {
  # Terraform 1.x の互換範囲を許可し、チーム内では lock file で Provider を固定する。
  required_version = ">= 1.8.3, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.49"
    }
  }
}

provider "aws" {
  # PRD アカウントと東京リージョンを明示し、誤った環境への適用を防ぐ。
  profile = "prd"
  region  = "ap-northeast-1"

  default_tags {
    tags = {
      cGroup = "prd-test2"
    }
  }
}

terraform {
  # State の保存先を定義する。将来は S3 Backend へ移行する想定。
  backend "s3" {
    bucket = "zhu-terraform-state-bucket"
    key    = "prd/terraform.tfstate"
    region = "ap-northeast-1"
    # Backend 初期化時は Provider 設定を参照しないため、使用する AWS Profile をここでも指定する。
    profile = "prd"
    encrypt = true

    # Terraform 1.8.3 は use_lockfile に未対応。
    # 複数人で同時に操作する場合は、後で DynamoDB による State Lock を設定する。
  }
}
