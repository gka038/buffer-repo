include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  frontend_json = jsondecode(templatefile(find_in_parent_folders("frontend.json"), {}))
  zone_list     = distinct([for v in local.frontend_json : v.zone])
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/acm?ref=development"
}

skip = (local.acm.locals.custom_default_cert_arn == "" ? false : true)

dependency "route53_zone" {
  config_path  = find_in_parent_folders("00-initial-infra/route53/zone")
  skip_outputs = true
}

inputs = {
  project_name        = local.spryker.locals.project_name
  route53_zone_domain = local.spryker.locals.route53_zone_domain
  zone_list           = { for zone in local.zone_list : zone => distinct(concat([ for domain, v in local.frontend_json : domain if v.zone == zone ], [zone])) }
}
