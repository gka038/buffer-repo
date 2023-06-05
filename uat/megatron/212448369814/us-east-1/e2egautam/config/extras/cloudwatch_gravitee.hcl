locals {
  enabled                        = false
  cloudwatch_alarm_statistic     = "Sum"
  cloudwatch_alarm_threshold     = "1"
  cloudwatch_alarm_period        = "300"
  cloudwatch_alarm_eval_period   = "1"
  cloudwatch_alarm_comp_operator = "GreaterThanOrEqualToThreshold"
  application_name               = "zed"
}
