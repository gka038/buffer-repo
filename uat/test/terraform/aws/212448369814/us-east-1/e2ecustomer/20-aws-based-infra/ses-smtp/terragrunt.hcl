include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ses-smtp.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/ses_smtp?ref=23_02.0"
}

dependency "route53_zone" {
  config_path = find_in_parent_folders("00-initial-infra/route53/zone")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    zone_name = "mock"
  }
}

skip = local.aws-based-infra.locals.external_zone

inputs = {
  dmarc_reports       = local.aws-based-infra.locals.dmarc_reports
  route53_zone_domain = dependency.route53_zone.outputs.zone_name
}
