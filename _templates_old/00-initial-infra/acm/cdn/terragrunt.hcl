include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  s3_cdn_config = read_terragrunt_config(find_in_parent_folders("config/extras/s3_cdn.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/acm/cdn?ref=v9.0.0"
}

inputs = {
  cdn                 = local.s3_cdn_config.locals.enabled ? local.s3_cdn_config.locals.s3_buckets : []
  route53_zone_domain = local.spryker.locals.route53_zone_domain
}
