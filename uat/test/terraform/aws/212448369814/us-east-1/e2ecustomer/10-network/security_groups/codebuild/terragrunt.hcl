include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  network = read_terragrunt_config(find_in_parent_folders("config/network/sg.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/vpc_security_group?ref=23_02.0"
}

dependency "vpc_network" {
  config_path = find_in_parent_folders("10-network/vpc")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    vpc_id = "mock"
  }
}

inputs = {
  project_name = local.spryker.locals.project_name
  sg_name      = local.network.locals.codebuild.name
  vpc_id       = dependency.vpc_network.outputs.vpc_id
  sg_rules     = local.network.locals.codebuild.sg_rules
}
