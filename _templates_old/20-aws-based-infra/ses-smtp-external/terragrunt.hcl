include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ses-smtp.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/ses_smtp_external?ref=v9.0.0"
}

skip = !local.aws-based-infra.locals.external_zone

inputs = {
  external_domain_identity  = local.aws-based-infra.locals.external_domain_identity
  external_domain_mail_from = local.aws-based-infra.locals.external_domain_mail_from
}
