include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  rds     = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/rds.hcl"))
}

skip = !local.rds.locals.backup.enabled

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/sns_topic?ref=23_01.0"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name               = local.spryker.locals.project_name
  topic_name                 = "backup-vault-events"
  create_subscription        = true
  subscription_protocol      = "https"
  subscription_endpoint      = [format("%s%s", local.rds.locals.backup.sns_opsgenie_endpoint_url, dependency.vault_secrets.outputs.spryker_secrets["opsgenie_api_key"])]
  subscription_filter_policy = local.rds.locals.backup.filter_policy
  aws_service_publish        = "backup.amazonaws.com"
}
