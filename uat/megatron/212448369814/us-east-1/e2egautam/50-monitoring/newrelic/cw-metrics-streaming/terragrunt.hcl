include {
  path = find_in_parent_folders()
}

locals {
  spryker  = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  newrelic = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/cw-metrics-exporter?ref=23_01.0"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

skip = !local.newrelic.locals.newrelic_customer_account.enable_integration

inputs = {
  # customer's dedicated NR account
  newrelic_account_id = dependency.vault_secrets.outputs.spryker_secrets["newrelic_account_id"]
  newrelic_api_key    = dependency.vault_secrets.outputs.spryker_secrets["newrelic_license_key"]

  newrelic_collector_endpoint             = local.newrelic.locals.newrelic_collector_endpoint
  name_prefix                             = "${local.spryker.locals.project_name}-"
  aws_region                              = local.spryker.locals.region
  cloudwatch_metric_stream_include_filter = local.newrelic.locals.cloudwatch_metric_stream_include_filter
}
