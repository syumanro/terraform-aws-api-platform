# -----------------------------------------------------------------------------
# Network Module
# -----------------------------------------------------------------------------

module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  common_tags  = local.common_tags

  availability_zones         = var.availability_zones
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_app_subnet_cidrs   = var.private_app_subnet_cidrs
  private_db_subnet_cidrs    = var.private_db_subnet_cidrs
  private_cache_subnet_cidrs = var.private_cache_subnet_cidrs
}

# -----------------------------------------------------------------------------
# Load Balancer Module
# -----------------------------------------------------------------------------

module "load_balancer" {
  source = "../../modules/load-balancer"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags

  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids
  nlb_security_group_id  = module.network.nlb_security_group_id
  alb_security_group_id  = module.network.alb_security_group_id
  # alb_certificate_arn     = var.alb_certificate_arn
}

# -----------------------------------------------------------------------------
# ECR Module
# -----------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}

# -----------------------------------------------------------------------------
# ECS Module
# -----------------------------------------------------------------------------

module "ecs" {
  source = "../../modules/ecs"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags

  private_app_subnet_ids = module.network.private_app_subnet_ids
  ecs_security_group_id  = module.network.ecs_security_group_id
  target_group_arn       = module.load_balancer.ecs_target_group_arn

  task_definition_arn               = var.task_definition_arn
  desired_count                     = var.desired_count
  health_check_grace_period_seconds = var.health_check_grace_period_seconds
}

# -----------------------------------------------------------------------------
# Aurora Module
# -----------------------------------------------------------------------------

module "aurora" {
  source = "../../modules/aurora"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags

  private_db_subnet_ids    = module.network.private_db_subnet_ids
  aurora_security_group_id = module.network.aurora_security_group_id

  database_name   = var.database_name
  master_username = var.database_master_username
  master_password = var.database_master_password
  instance_class  = var.aurora_instance_class
}

# -----------------------------------------------------------------------------
# Redis Module
# -----------------------------------------------------------------------------

module "redis" {
  source = "../../modules/redis"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags

  private_cache_subnet_ids = module.network.private_cache_subnet_ids
  redis_security_group_id  = module.network.redis_security_group_id

  node_type      = var.redis_node_type
  engine_version = var.redis_engine_version
}
