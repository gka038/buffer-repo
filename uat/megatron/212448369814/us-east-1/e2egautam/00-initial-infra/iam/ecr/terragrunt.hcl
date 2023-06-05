include {
  path = find_in_parent_folders()
}

locals {
  spryker    = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  custom_ecr = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ecr.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/ecr?ref=23_01.0"
}

dependency "aws_data" {
  config_path = find_in_parent_folders("00-initial-infra/aws-data")

  
  mock_outputs = {
    account_id = 123456789012
  }
}

inputs = {
  project_name    = local.spryker.locals.project_name
  region          = local.spryker.locals.region
  aws_account_id  = dependency.aws_data.outputs.account_id
  custom_ecr_name = local.custom_ecr.locals.custom_ecr_name
}
