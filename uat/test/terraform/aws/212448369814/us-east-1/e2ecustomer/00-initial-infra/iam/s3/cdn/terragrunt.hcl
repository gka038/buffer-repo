include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  s3_cdn_config = read_terragrunt_config(find_in_parent_folders("config/extras/s3_cdn.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/iam/s3/cdn?ref=23_02.0"
}

skip = !local.s3_cdn_config.locals.enabled

dependency "iam_customer" {
  config_path = find_in_parent_folders("00-initial-infra/iam/customer")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    customer_group_name = "mock"
  }
}

dependency "s3_cdn" {
  config_path = find_in_parent_folders("00-initial-infra/s3/cdn")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    s3_bucket_details      = []
    s3_bucket_iam_policies = []
  }
}

inputs = {
  cdn                    = local.s3_cdn_config.locals.s3_buckets
  customer_group_name    = dependency.iam_customer.outputs.customer_group_name
  s3_bucket_arn          = dependency.s3_cdn.outputs.s3_bucket_details
  s3_bucket_iam_policies = dependency.s3_cdn.outputs.s3_bucket_iam_policies
}
