

include {
  path = find_in_parent_folders()
}

locals {
  spryker          = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  composer_content = read_terragrunt_config(find_in_parent_folders("config/extras/composer_content.hcl"))
  gmv_cc_shared    = read_terragrunt_config(find_in_parent_folders("config/extras/gmv_and_composer_shared.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/spryker_secrets_manager?ref=23_01.0"
}

skip = !local.gmv_cc_shared.locals.gmv_enabled

dependency "rds" {
  config_path = find_in_parent_folders("20-aws-based-infra/rds")

  
  mock_outputs = {
    replica_endpoints = []
    username          = "mock"
    db_password       = "mock"
    db_name           = "mock"
    port              = 0
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name    = local.spryker.locals.project_name
  secret_name     = "gmv_and_cc_secrets"
  secret_contents = merge({
    "aws-access-key-id" : dependency.vault_secrets.outputs.spryker_secrets["gmv_aws_access_key"],
    "aws-secret-access-key" : dependency.vault_secrets.outputs.spryker_secrets["gmv_aws_secret_access_key"],
    "bucket-name" : dependency.vault_secrets.outputs.spryker_secrets["gmv_bucket_name"],
    "region-name" : dependency.vault_secrets.outputs.spryker_secrets["gmv_bucket_region"]
  }, {
    "host" : length(dependency.rds.outputs.replica_endpoints) > 0 ? dependency.rds.outputs.replica_endpoints[0] : "",
    "port" : dependency.rds.outputs.port,
    "username" : dependency.rds.outputs.username,
    "password" : dependency.rds.outputs.db_password,
    "dbname" : dependency.rds.outputs.db_name
  }
  )
}

