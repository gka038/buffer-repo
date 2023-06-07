include {
  path = find_in_parent_folders()
}

locals {
  spryker          = read_terragrunt_config("${get_parent_terragrunt_dir()}/config/common/spryker.hcl")
  spryker-services = read_terragrunt_config("${get_parent_terragrunt_dir()}/config/spryker-services/ec2_scheduler.hcl")
  source_module    = local.spryker.locals.scheduler_type == "ec2" ? "opsgenie_notification" : "empty_module"
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/${local.source_module}?ref=23_02.0"
}

dependency "target-groups" {
  config_path = find_in_parent_folders("30-spryker-services/scheduler/ec2/target-groups")

  mock_outputs = {
    arn_suffix = "arn:aws:iam::123456789012:mock"
  }
}

dependency "nlb" {
  config_path = find_in_parent_folders("10-network/lb/internal_nlb")

  mock_outputs = {
    arn_suffix = "arn:aws:iam::123456789012:mock"
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  project_name              = local.spryker.locals.project_name
  opsgenie_api_key          = dependency.vault_secrets.outputs.spryker_secrets["opsgenie_jenkins_failure_notifications_api_key"]
  aws_sns_topic_name_suffix = "failure-${local.spryker-services.locals.instance_name}"
  alarm_configuration       = local.spryker-services.locals.alarm_configuration
  alarm_dimensions = {
    TargetGroup  = dependency.target-groups.outputs.arn_suffix
    LoadBalancer = dependency.nlb.outputs.arn_suffix
  }
}
