include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  s3_cdn_config = read_terragrunt_config(find_in_parent_folders("config/extras/s3_cdn.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/acm/cdn?ref=23_02.0"
}

dependency "route53_zone" {
  config_path  = find_in_parent_folders("00-initial-infra/route53/zone")
  skip_outputs = true
}

inputs = {
  cdn                 = local.s3_cdn_config.locals.enabled ? local.s3_cdn_config.locals.s3_buckets : []
  route53_zone_domain = local.spryker.locals.route53_zone_domain
}
