include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  initial-infra = read_terragrunt_config(find_in_parent_folders("config/initial-infra/kms.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/kms/01-es?ref=23_01.0"
}

inputs = {
  project_name    = local.spryker.locals.project_name
  key_description = local.initial-infra.locals.search.key_description
}
