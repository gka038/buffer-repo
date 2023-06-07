include {
  path = find_in_parent_folders()
}

locals {
  spryker   = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  s3_config = read_terragrunt_config(find_in_parent_folders("config/extras/rds_dump_to_s3.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/iam/rds_dump_to_s3?ref=development"
}

skip = !local.s3_config.locals.enabled

dependency "iam_customer" {
  config_path = find_in_parent_folders("00-initial-infra/iam/customer")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    customer_group_name = "mock"
  }
}

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs = {
    internal_s3_bucket_arn = []
  }
}

inputs = {
  rds_dump_to_s3_enable = local.s3_config.locals.enabled
  project_name          = local.spryker.locals.project_name
  customer_group_name   = dependency.iam_customer.outputs.customer_group_name
  s3_bucket_arn         = length(dependency.s3.outputs.internal_s3_bucket_arn) > 0 ? dependency.s3.outputs.internal_s3_bucket_arn : null
}
