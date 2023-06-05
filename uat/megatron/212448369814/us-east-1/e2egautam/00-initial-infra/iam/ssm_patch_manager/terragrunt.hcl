include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/ssm_patch_manager?ref=development"
}

dependency "s3_ssm" {
  config_path = find_in_parent_folders("00-initial-infra/s3/ssm_patch_manager")

  mock_outputs = {
    ssm_s3_bucket_arn = ""
  }
}

inputs = {
  project_name = local.spryker.locals.project_name
  s3_arn       = dependency.s3_ssm.outputs.ssm_s3_bucket_arn
}
