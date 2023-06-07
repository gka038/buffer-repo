include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/ssm.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/ssm?ref=development"
}

dependency "iam_slr" {
  config_path = find_in_parent_folders("00-initial-infra/iam/service-linked-roles")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_service_linked_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "iam_ssm" {
  config_path = find_in_parent_folders("00-initial-infra/iam/ssm")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_automation_iam_role_arn = "mock"
  }
}

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    internal_s3_bucket_name = "mock"
  }
}

dependency "ssm" {
  config_path = find_in_parent_folders("00-initial-infra/ssm")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_parameter_address = { ssm_ansible_password = { id = "mock" } }
  }
}

dependency "ec2_bastion" {
  config_path = find_in_parent_folders("10-network/ec2/bastion")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    instance_id = "mock"
  }
}

inputs = {
  project_name                     = local.spryker.locals.project_name
  ansible                          = local.aws-based-infra.locals.ansible
  schedule                         = local.aws-based-infra.locals.schedule
  apply_rollback                   = local.aws-based-infra.locals.apply_rollback
  ssm_service_linked_role_arn      = dependency.iam_slr.outputs.ssm_service_linked_role_arn
  bastion_id                       = dependency.ec2_bastion.outputs.instance_id
  ssm_automation_iam_role_arn      = dependency.iam_ssm.outputs.ssm_automation_iam_role_arn
  s3_bucket_name                   = dependency.s3.outputs.internal_s3_bucket_name
  ssm_ansible_parameter_address_id = dependency.ssm.outputs.ssm_parameter_address.ssm_ansible_password.id
}
