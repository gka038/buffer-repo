include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/evm?ref=23_01.0"
}

inputs = {
  project_name  = local.spryker.locals.project_name
  project_owner = local.spryker.locals.project_owner
  env_type      = local.spryker.locals.env_type
}
