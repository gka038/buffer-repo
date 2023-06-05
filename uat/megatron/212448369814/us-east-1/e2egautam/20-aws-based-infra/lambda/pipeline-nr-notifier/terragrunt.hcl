include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  spryker-secrets = read_terragrunt_config(find_in_parent_folders("config/common/secrets.hcl"))
  newrelic        = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/lambda/newrelic_notificator?ref=23_01.0"
}

dependency "lambda" {
  config_path = find_in_parent_folders("00-initial-infra/iam/lambda")

  
  mock_outputs = {
    lambda_iam_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name                   = local.spryker.locals.project_name
  newrelic_pipeline_iam_role_arn = dependency.lambda.outputs.lambda_iam_role_arn
  newrelic_account_id            = dependency.vault_secrets.outputs.spryker_secrets["newrelic_metrics_account_id"]
  newrelic_ingest_key            = dependency.vault_secrets.outputs.spryker_secrets["newrelic_metrics_ingest_key"]
  newrelic_account_type          = local.newrelic.locals.newrelic_integration.newrelic_account_type
}

