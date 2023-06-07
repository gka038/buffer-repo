include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/iam/ssm_patch_manager?ref=development"
}

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs = {
    internal_s3_bucket_arn = ""
  }
}

inputs = {
  project_name = local.spryker.locals.project_name
  s3_arn       = dependency.s3.outputs.internal_s3_bucket_arn
}
