include {
  path = find_in_parent_folders()
}

locals {
  spryker  = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  newrelic = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/newrelic?ref=development"
}

skip = !local.newrelic.locals.newrelic_integration.enable_production_mode

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs                            = {
    internal_s3_bucket_name = "mock"
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name                    = local.spryker.locals.project_name
  project_owner                   = local.spryker.locals.project_owner
  env_type                        = local.spryker.locals.env_type
  aws_integration                 = local.newrelic.locals.aws_integration
  synthetics_yves_urls            = local.newrelic.locals.synthetics_yves_urls
  synthetics_healthcheck_settings = local.newrelic.locals.synthetics_healthcheck_settings
  s3_bucket_name                  = dependency.s3.outputs.internal_s3_bucket_name
  newrelic_integration            = merge({
    "license_key" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_license_key"]
    "newrelic_apm_license_key" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_apm_license_key"]
    "insights_key" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_insights_key"]
    "api_key" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_api_key"]
    "account_id" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_account_id"]
    "opsgenie_api_key" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_opsgenie_api_key"] },
    local.newrelic.locals.newrelic_integration)
  basic_auth                      = {
    "user" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_user"]
    "password" : dependency.vault_secrets.outputs.spryker_secrets["newrelic_password"]
  }
}
