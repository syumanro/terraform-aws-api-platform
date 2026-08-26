variable "vpc_id" {
  type    = string
  default = "vpc-0c6c279cbe866931b"
}

variable "ecs_a_subnet_cidr" {
  description = "ap-northeast-1a など、ECS 用プライベートサブネットの CIDR ブロック。"
  type        = string
  # 既存の public/app/db/cache 用 CIDR と重複しない ECS 専用範囲。
  default = "172.31.11.0/24"
}

variable "ecs_c_subnet_cidr" {
  description = "ap-northeast-1c など、ECS 用プライベートサブネットの CIDR ブロック。"
  type        = string
  # 2 つ目の AZ 用。1 つ目と分離することで AZ 障害に備える。
  default = "172.31.12.0/24"
}

variable "alb_certificate_arn" {
  description = "ALB HTTPS listener 用の ACM 証明書 ARN。未指定の場合はテスト用 HTTP listener を使用する。"
  type        = string
  default     = null
  nullable    = true
}
