include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/lambda.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/lambda/rds/start?ref=23_02.0"
}

skip = !local.aws-based-infra.locals.rds_stop_start_enabled

dependency "rds" {
  config_path = find_in_parent_folders("00-initial-infra/iam/rds")
}

inputs = {
  project_name        = local.spryker.locals.project_name
  lambda_iam_role_arn = dependency.rds.outputs.rds_lambda_role_arn
  start_schedule      = local.aws-based-infra.locals.start_schedule
}
