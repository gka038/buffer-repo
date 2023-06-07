include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  sns     = read_terragrunt_config(find_in_parent_folders("config/initial-infra/sns.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/sns_topic?ref=23_02.0"
}

inputs = {
  project_name          = local.spryker.locals.project_name
  topic_name            = "deployment-notification"
  create_subscription   = true
  subscription_protocol = "email"
  subscription_endpoint = local.sns.locals.sns_notification_emails
}
