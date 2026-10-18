# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = var.vpc_id
  tags = {
    Name = "zhu-prd-test2-igw"
  }
}

# Public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = var.vpc_id
  cidr_block              = "172.31.21.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "zhu-prd-test2-alb-ap-northeast-1a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = var.vpc_id
  cidr_block              = "172.31.22.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "zhu-prd-test2-alb-ap-northeast-1c"
    Tier = "public"
  }
}

# Public routing
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "zhu-prd-test2-alb-public-rt"
    Tier = "public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# ECS subnets: learning mode uses public IPs and avoids NAT Gateway costs.
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

# ECS outbound routing
resource "aws_route_table" "ecs_private" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "zhu-prd-test2-ecs-private-rt"
    Tier = "ecs"
  }
}

resource "aws_route_table_association" "ecs_a" {
  subnet_id      = aws_subnet.ecs_a.id
  route_table_id = aws_route_table.ecs_private.id
}

resource "aws_route_table_association" "ecs_c" {
  subnet_id      = aws_subnet.ecs_c.id
  route_table_id = aws_route_table.ecs_private.id
}
