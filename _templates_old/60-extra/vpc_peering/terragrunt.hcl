include {
  path = find_in_parent_folders()
}

locals {
  vpc_peering_settings = read_terragrunt_config(find_in_parent_folders("config/extras/vpc_peering.hcl"))
  redis_settings       = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/elasticache.hcl"))
  spryker              = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/vpc_peering?ref=v9.0.0"
}

skip = !local.vpc_peering_settings.locals.enabled

dependency "mariadb" {
  config_path = find_in_parent_folders("20-aws-based-infra/rds")
}

dependency "sg_main" {
  config_path = find_in_parent_folders("10-network/security_groups/initial")
}

dependency "sg_redis" {
  config_path = find_in_parent_folders("10-network/security_groups/redis")
}

dependency "sg_rds" {
  config_path = find_in_parent_folders("10-network/security_groups/rds")
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")
}

inputs = {
  project_name                  = local.spryker.locals.project_name
  rds_port                      = dependency.mariadb.outputs.port
  redis_port                    = local.redis_settings.locals.settings.port
  vpc_id                        = dependency.vpc.outputs.vpc_id
  vpc_peering_owner_id          = local.vpc_peering_settings.locals.vpc_peering_owner_id
  vpc_peering_vpc_id            = local.vpc_peering_settings.locals.vpc_peering_vpc_id
  vpc_peering_cidr              = local.vpc_peering_settings.locals.vpc_peering_cidr
  main_security_group_id        = dependency.sg_main.outputs.security_group
  rds_security_group_id         = dependency.sg_rds.outputs.security_group
  elasticache_security_group_id = dependency.sg_redis.outputs.security_group
  vpc_peering_tag               = local.vpc_peering_settings.locals.vpc_peering_tag
  vpc_peering_accepter          = local.vpc_peering_settings.locals.vpc_peering_accepter
}
