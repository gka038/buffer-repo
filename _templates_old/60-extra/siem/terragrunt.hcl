include {
  path = find_in_parent_folders()
}

locals {
  siem = read_terragrunt_config(find_in_parent_folders("config/extras/siem.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/siem?ref=development"
}

inputs = {
  ssm_log_group_name = local.siem.locals.ssm_log_group_name
  enable_cwl_subscriptions = local.siem.locals.enable_cwl_subscriptions
  enable_ssm_s3_audit = local.siem.locals.enable_ssm_s3_audit
  enable_cwl_subscriptions_roles = local.siem.locals.enable_cwl_subscriptions_roles
}
