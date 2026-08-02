# -----------------------------------------------------------------------------
# Network Module
# -----------------------------------------------------------------------------

module "network" {
  source = "../../modules/network"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  common_tags  = local.common_tags

  availability_zones        = var.availability_zones
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_app_subnet_cidrs   = var.private_app_subnet_cidrs
  private_db_subnet_cidrs    = var.private_db_subnet_cidrs
  private_cache_subnet_cidrs = var.private_cache_subnet_cidrs
}