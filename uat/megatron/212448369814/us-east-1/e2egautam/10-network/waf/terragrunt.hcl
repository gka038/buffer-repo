include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  waf     = read_terragrunt_config(find_in_parent_folders("config/network/waf.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/waf?ref=23_01.0"
}

dependency "external_alb" {
  config_path = find_in_parent_folders("10-network/lb/external_alb")

  
  mock_outputs = {
    alb_arn = "arn:aws:iam::123456789012:mock"
  }
}

skip = !local.waf.locals.waf_enabled

inputs = {
  project_name                             = local.spryker.locals.project_name
  frontend_elb_arn                         = dependency.external_alb.outputs.alb_arn
  cloudwatch_metrics_enabled               = local.waf.locals.cloudwatch_metrics_enabled
  common_custom_exclusion                  = local.waf.locals.common_custom_exclusion
  negated_scopedown_sqli_ruleset           = local.waf.locals.negated_scopedown_sqli_ruleset
  regex_scopedown_admin_protection_ruleset = local.waf.locals.regex_scopedown_admin_protection_ruleset
  managed_sqli_ruleset                     = local.waf.locals.managed_sqli_ruleset
}
