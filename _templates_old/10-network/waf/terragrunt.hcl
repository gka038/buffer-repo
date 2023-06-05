include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  waf     = read_terragrunt_config(find_in_parent_folders("config/network/waf.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/waf?ref=v9.0.0"
}

dependency "external_alb" {
  config_path = find_in_parent_folders("10-network/lb/external_alb")
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
