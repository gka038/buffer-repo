include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/acm?ref=23_01.0"
}

dependency "route53_zone" {
  config_path  = find_in_parent_folders("00-initial-infra/route53/zone")
  skip_outputs = true
}

inputs = {
  zone_name         = local.spryker.locals.route53_zone_domain
  alternative_names = [for domain, v in jsondecode(templatefile(find_in_parent_folders("frontend.json"), {})) : domain]
}
