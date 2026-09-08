# -----------------------------------------------------------------------------
# NLB 用パブリック Subnet
# Internet Gateway へ到達できる 2 AZ の Subnet を作成し、インターネット向け
# NLB を配置する。
# -----------------------------------------------------------------------------

# Internet Gateway が存在しない空の既存 VPC に Gateway を作成する。
resource "aws_internet_gateway" "main" {
  vpc_id = var.vpc_id

  tags = {
    Name = "zhu-prd-test2-igw"
  }
}

# インターネット向け NLB を 2 AZ に分散するためのパブリック Subnet。
resource "aws_subnet" "nlb_a" {
  vpc_id                  = var.vpc_id
  cidr_block              = "172.31.21.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "zhu-prd-test2-nlb-ap-northeast-1a"
    Tier = "public"
  }
}

resource "aws_subnet" "nlb_c" {
  vpc_id                  = var.vpc_id
  cidr_block              = "172.31.22.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "zhu-prd-test2-nlb-ap-northeast-1c"
    Tier = "public"
  }
}

# NLB 用 Subnet の 0.0.0.0/0 を Internet Gateway へ送る Public Route Table。
resource "aws_route_table" "nlb_public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "zhu-prd-test2-nlb-public-rt"
    Tier = "public"
  }
}

resource "aws_route_table_association" "nlb_a" {
  subnet_id      = aws_subnet.nlb_a.id
  route_table_id = aws_route_table.nlb_public.id
}

resource "aws_route_table_association" "nlb_c" {
  subnet_id      = aws_subnet.nlb_c.id
  route_table_id = aws_route_table.nlb_public.id
}

# -----------------------------------------------------------------------------
# ECS 用プライベートサブネット
# ECS タスクにはパブリック IP を割り当てない。外部通信が必要な場合は、
# NAT Gateway または VPC Endpoint を後から ECS 用 Route Table に追加する。
# -----------------------------------------------------------------------------

# AZ を分散して単一 AZ 障害でも ECS を継続できるようにする 1 つ目の私有サブネット。
resource "aws_subnet" "ecs_a" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.ecs_a_subnet_cidr
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "zhu-prd-ecs-ap-northeast-1a"
    Tier = "ecs"
  }
}

# AZ を分散して可用性を高める 2 つ目の私有サブネット。
resource "aws_subnet" "ecs_c" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.ecs_c_subnet_cidr
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "zhu-prd-ecs-ap-northeast-1c"
    Tier = "ecs"
  }
}

# ECS 専用のプライベート Route Table を新規作成する。
# インターネット向けのデフォルトルートは持たせず、外部公開を防ぐ。
resource "aws_route_table" "ecs_private" {
  vpc_id = var.vpc_id

  tags = {
    Name = "zhu-prd-test2-ecs-private-rt"
    Tier = "ecs"
  }
}

# ECS サブネットを新規プライベート Route Table へ関連付ける。
resource "aws_route_table_association" "ecs_a" {
  subnet_id      = aws_subnet.ecs_a.id
  route_table_id = aws_route_table.ecs_private.id
}

# 両方の AZ で同じ通信方針を適用するための Route Table 関連付け。
resource "aws_route_table_association" "ecs_c" {
  subnet_id      = aws_subnet.ecs_c.id
  route_table_id = aws_route_table.ecs_private.id
}
