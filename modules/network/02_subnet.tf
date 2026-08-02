# -----------------------------------------------------------------------------
# Public Subnets
# -----------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
      Tier = "public"
    }
  )
}

# -----------------------------------------------------------------------------
# Private Application Subnets
# -----------------------------------------------------------------------------

resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_app_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-app-${var.availability_zones[count.index]}"
      Tier = "application"
    }
  )
}

# -----------------------------------------------------------------------------
# Private Database Subnets
# -----------------------------------------------------------------------------

resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_db_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-db-${var.availability_zones[count.index]}"
      Tier = "database"
    }
  )
}

# -----------------------------------------------------------------------------
# Private Cache Subnets
# -----------------------------------------------------------------------------

resource "aws_subnet" "private_cache" {
  count = length(var.private_cache_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_cache_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-cache-${var.availability_zones[count.index]}"
      Tier = "cache"
    }
  )
}