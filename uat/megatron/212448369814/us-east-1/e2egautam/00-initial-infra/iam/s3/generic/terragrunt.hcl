include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  initial-infra = read_terragrunt_config(find_in_parent_folders("config/initial-infra/s3.hcl"))
  bucket_list   = read_terragrunt_config(find_in_parent_folders("config/extras/custom_s3_buckets.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/s3?ref=23_01.0"
}

skip = !local.bucket_list.locals.enabled

dependency "iam_customer" {
  config_path = find_in_parent_folders("00-initial-infra/iam/customer")

  
  mock_outputs = {
    customer_group_name = "mock"
  }
}

dependency "s3_generic" {
  config_path = find_in_parent_folders("60-extra/custom_s3_buckets")

  mock_outputs = {
    bucket_arn = ""
  }
}

inputs = {
  project_name        = local.spryker.locals.project_name
  s3_settings         = local.initial-infra.locals.generic.s3_settings
  s3_arn              = dependency.s3_generic.outputs.bucket_arn
  customer_group_name = dependency.iam_customer.outputs.customer_group_name
}
