include {
  path = find_in_parent_folders()
}

locals {
  bucket_list = read_terragrunt_config(find_in_parent_folders("config/extras/custom_s3_buckets.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/s3/generic?ref=23_01.0"
}

inputs = {
  s3_buckets = local.bucket_list.locals.enabled ? local.bucket_list.locals.s3_buckets : []
}
