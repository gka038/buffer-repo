include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  rds     = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/rds.hcl"))
}

skip = !local.rds.locals.backup.enabled

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/rds_backup?ref=23_02.0"
}

dependency "iam" {
  config_path = find_in_parent_folders("00-initial-infra/iam/rds_backup")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    backup_iam_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "sns" {
  config_path = find_in_parent_folders("00-initial-infra/sns_topics/rds_backup")

  mock_outputs = {
    sns_topic_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "rds_instance" {
  config_path = find_in_parent_folders("20-aws-based-infra/rds")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    db_arn = "arn:aws:iam::123456789012:mock"
  }
}

inputs = {
  project_name         = local.spryker.locals.project_name
  vault_name           = local.rds.locals.backup.vault_name
  hourly_period        = local.rds.locals.backup.hourly_period
  daily_time           = local.rds.locals.backup.daily_time
  max_retention        = local.rds.locals.backup.max_retention
  tags                 = local.spryker.locals.tags
  notifications        = local.rds.locals.backup.notifications
  selection_resources  = [dependency.rds_instance.outputs.db_arn]
  backup_iam_role_arn  = dependency.iam.outputs.backup_iam_role_arn
  backup_sns_topic_arn = dependency.sns.outputs.sns_topic_arn
}
