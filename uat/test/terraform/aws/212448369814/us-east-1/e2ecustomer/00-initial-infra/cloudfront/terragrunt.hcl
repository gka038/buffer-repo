include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  s3_cdn_config = read_terragrunt_config(find_in_parent_folders("config/extras/s3_cdn.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/cloudfront?ref=development"
}

dependency "s3_cdn" {
  config_path = find_in_parent_folders("00-initial-infra/s3/cdn")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    s3_bucket_details = []
  }
}

dependency "acm_cdn" {
  config_path = find_in_parent_folders("00-initial-infra/acm/cdn")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    aws_acm_certificate_arn = []
  }
}

inputs = {
  cdn                        = local.s3_cdn_config.locals.enabled ? local.s3_cdn_config.locals.s3_buckets : []
  s3_bucket_website_endpoint = dependency.s3_cdn.outputs.s3_bucket_details
  aws_acm_certificate_arn    = dependency.acm_cdn.outputs.aws_acm_certificate_arn
}
