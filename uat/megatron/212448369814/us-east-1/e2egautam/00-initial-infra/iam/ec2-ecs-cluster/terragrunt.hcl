include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/ec2/ecs-cluster?ref=development"
}

dependency "iam_s3_ssm" {
  config_path = find_in_parent_folders("00-initial-infra/iam/ssm_patch_manager")

  mock_outputs = {
    s3_ssm_automation_patch_policy_arn = ""
  }
}

inputs = {
  project_name                       = local.spryker.locals.project_name
  s3_ssm_automation_patch_policy_arn = dependency.iam_s3_ssm.outputs.s3_ssm_automation_patch_policy_arn
}
