include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  ssm_patch_manager = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ssm_patch_manager.hcl"))
}

skip = !local.ssm_patch_manager.locals.cloudwatch.enabled

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/cloudwatch/ssm_patch_manager?ref=development"
}

inputs = {
  project_name                      = local.spryker.locals.project_name
  cloudwatch_log_group_rotation_day = local.ssm_patch_manager.locals.cloudwatch.log_group_rotation_day
}
