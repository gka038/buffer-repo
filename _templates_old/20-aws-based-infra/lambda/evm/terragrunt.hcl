include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  spryker-secrets = read_terragrunt_config(find_in_parent_folders("config/common/secrets.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/lambda/evm?ref=v8.0.0"
}

dependency "iam" {
  config_path = find_in_parent_folders("00-initial-infra/iam/evm")
}

inputs = {
  project_name  = local.spryker.locals.project_name
  iam_role_arn  = dependency.iam.outputs.lambda_iam_role_arn
}
