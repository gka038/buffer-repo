include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  ssm_patch_manager = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ssm_patch_manager.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/s3/ssm_patch_manager?ref=development"
}

inputs = {
  project_name = local.spryker.locals.project_name
}
