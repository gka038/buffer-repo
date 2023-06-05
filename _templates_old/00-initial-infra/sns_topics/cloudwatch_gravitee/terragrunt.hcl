include {
  path = find_in_parent_folders()
}

locals {
  spryker  = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  gravitee = read_terragrunt_config(find_in_parent_folders("config/extras/cloudwatch_gravitee.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/sns_topic?ref=v9.0.0"
}

skip = !local.gravitee.locals.enabled

inputs = {
  project_name        = local.spryker.locals.project_name
  topic_name          = "cloudwatch_gravitee"
  create_subscription = false
}
