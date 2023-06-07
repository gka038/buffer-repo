include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/elasticache.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/elasticache?ref=23_02.0"
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    private_middle_subnet     = []
    private_middle_subnet_ids = ["mock"]
  }
}

dependency "sg" {
  config_path = find_in_parent_folders("10-network/security_groups/redis")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    security_group = "mock"
  }
}

inputs = {
  project_name       = local.spryker.locals.project_name
  private_subnet_ids = dependency.vpc.outputs.private_middle_subnet_ids
  security_group     = [dependency.sg.outputs.security_group]
  redis_settings = merge(
    local.aws-based-infra.locals.settings,
    { "availability_zones" = [for subnet in dependency.vpc.outputs.private_middle_subnet : subnet.availability_zone] }
  )
}
