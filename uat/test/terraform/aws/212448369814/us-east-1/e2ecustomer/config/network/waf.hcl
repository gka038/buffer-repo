locals {
  waf_enabled                              = false
  managed_sqli_ruleset                     = true
  cloudwatch_metrics_enabled               = false
  common_custom_exclusion                  = []
  negated_scopedown_sqli_ruleset           = []
  regex_scopedown_admin_protection_ruleset = []
}
