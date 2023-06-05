include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  rds     = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/rds.hcl"))
}

skip = !local.rds.locals.backup.enabled

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/sns_topics/rds_backup?ref=v8.0.0"
}

inputs = {
  project_name              = local.spryker.locals.project_name
  tags                      = local.spryker.locals.tags
  sns_opsgenie_endpoint_url = local.rds.locals.backup.sns_opsgenie_endpoint_url
  opsgenie_api_key          = local.rds.locals.backup.opsgenie_api_key
}

