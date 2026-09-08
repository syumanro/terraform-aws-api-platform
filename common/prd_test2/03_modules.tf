module "network" {
  source = "../../modules/network"

  vpc_id            = var.vpc_id
  ecs_a_subnet_cidr = var.ecs_a_subnet_cidr
  ecs_c_subnet_cidr = var.ecs_c_subnet_cidr
}

module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id = var.vpc_id
}

module "load_balancing" {
  source = "../../modules/load_balancing"

  vpc_id                = var.vpc_id
  nlb_subnet_ids        = module.network.nlb_subnet_ids
  ecs_subnet_ids        = module.network.ecs_subnet_ids
  nlb_security_group_id = module.security_groups.nlb_security_group_id
  alb_security_group_id = module.security_groups.alb_security_group_id
  alb_certificate_arn   = var.alb_certificate_arn
}

module "ecs" {
  source = "../../modules/ecs"

  vpc_id            = var.vpc_id
  subnet_ids        = module.network.ecs_subnet_ids
  security_group_id = module.security_groups.ecs_security_group_id
  target_group_arn  = module.load_balancing.production_target_group_arn

  depends_on = [module.load_balancing]
}

module "autoscaling" {
  source = "../../modules/autoscaling"

  cluster_name = module.ecs.cluster_name
  service_name = module.ecs.service_name
}

module "ecr" {
  source = "../../modules/ecr"
}

module "cicd" {
  source = "../../modules/cicd"

  github_repository            = var.github_repository
  github_branch                = var.github_branch
  github_connection_arn        = var.github_connection_arn
  ecr_repository_uri           = module.ecr.repository_url
  ecr_registry_id              = module.ecr.registry_id
  ecs_cluster_name             = module.ecs.cluster_name
  ecs_service_name             = module.ecs.service_name
  production_listener_arn      = module.load_balancing.production_listener_arn
  test_listener_arn            = module.load_balancing.test_listener_arn
  production_target_group_name = module.load_balancing.production_target_group_name
  test_target_group_name       = module.load_balancing.test_target_group_name
}
