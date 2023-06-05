include {
  path = find_in_parent_folders()
}

locals {
  spryker    = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  custom_ecr = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ecr.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/ecr?ref=23_01.0"
}

inputs = {
  project_name    = local.spryker.locals.project_name
  service_list    = local.spryker.locals.spryker_ecr_repos
  custom_ecr_name = local.custom_ecr.locals.custom_ecr_name
}
