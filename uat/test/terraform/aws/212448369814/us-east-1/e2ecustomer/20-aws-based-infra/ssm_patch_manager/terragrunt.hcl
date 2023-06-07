include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  ssm_patch_manager = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ssm_patch_manager.hcl"))
  ec2_scheduler     = read_terragrunt_config(find_in_parent_folders("config/spryker-services/ec2_scheduler.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/ssm_patch_manager?ref=development"
}

dependency "iam_slr" {
  config_path = find_in_parent_folders("00-initial-infra/iam/ssm_patch_manager")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_automation_patch_service_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "iam_ec2_instance" {
  config_path  = find_in_parent_folders("00-initial-infra/iam/ec2-ecs-cluster")
  skip_outputs = true
}

dependency "iam_ec2_scheduler_instance" {
  config_path  = find_in_parent_folders("00-initial-infra/iam/ec2-scheduler")
  skip_outputs = true
}

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    internal_s3_bucket_name = "mock"
  }
}

dependency "cloudwatch" {
  config_path = find_in_parent_folders("50-monitoring/cloudwatch/ssm_patch_manager")

  mock_outputs = {
    cloudwatch_log_group_name = "mock"
  }
}

inputs = {
  project_name                  = local.spryker.locals.project_name
  region                        = local.spryker.locals.region
  patch_schedule_critical       = local.ssm_patch_manager.locals.patch_schedule_critical
  patch_schedule_noncritical    = local.ssm_patch_manager.locals.patch_schedule_noncritical
  reboot_option                 = local.ssm_patch_manager.locals.reboot_option
  s3_bucket_name                = dependency.s3.outputs.internal_s3_bucket_name
  ssm_service_linked_role_arn   = dependency.iam_slr.outputs.ssm_automation_patch_service_role_arn
  ssm_cloudwatch_log_group_name = dependency.cloudwatch.outputs.cloudwatch_log_group_name
  s3_enabled                    = local.ssm_patch_manager.locals.s3.enabled
  cloudwatch_enabled            = local.ssm_patch_manager.locals.cloudwatch.enabled
  ec2_scheduler_instance_name   = local.ec2_scheduler.locals.instance_name
}
