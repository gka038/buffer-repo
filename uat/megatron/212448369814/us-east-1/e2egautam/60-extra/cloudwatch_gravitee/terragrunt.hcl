include {
  path = find_in_parent_folders()
}

locals {
  spryker  = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  gravitee = read_terragrunt_config(find_in_parent_folders("config/extras/cloudwatch_gravitee.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/cloudwatch/gravitee?ref=23_01.0"
}

skip = !local.gravitee.locals.enabled

dependency "aws_sns_topic" {
  config_path = find_in_parent_folders("00-initial-infra/sns_topics/cloudwatch_gravitee")

  mock_outputs = {
    sns_topic_arn = "arn:aws:iam::123456789012:mock"
  }
}

inputs = {
  project_name                   = local.spryker.locals.project_name
  application_name               = local.gravitee.locals.application_name
  cloudwatch_alarm_comp_operator = local.gravitee.locals.cloudwatch_alarm_comp_operator
  cloudwatch_alarm_eval_period   = local.gravitee.locals.cloudwatch_alarm_eval_period
  cloudwatch_alarm_period        = local.gravitee.locals.cloudwatch_alarm_period
  cloudwatch_alarm_threshold     = local.gravitee.locals.cloudwatch_alarm_threshold
  cloudwatch_alarm_statistic     = local.gravitee.locals.cloudwatch_alarm_statistic
  alarm_actions                  = [dependency.aws_sns_topic.outputs.sns_topic_arn]
}
