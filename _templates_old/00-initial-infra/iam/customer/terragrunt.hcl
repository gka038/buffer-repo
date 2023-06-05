include {
  path = find_in_parent_folders()
}

locals {
  spryker  = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  features = read_terragrunt_config(find_in_parent_folders("config/common/features.hcl"))
  iam      = read_terragrunt_config(find_in_parent_folders("config/initial-infra/iam.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/customer?ref=v8.0.0"
}

dependency "ssm" {
  config_path = find_in_parent_folders("00-initial-infra/ssm")
}

dependency "evm" {
  config_path = find_in_parent_folders("00-initial-infra/iam/evm")
}


inputs = {
  attach_policy_arns       = local.iam.locals.customer.additional_policy_arns
  project_name             = local.spryker.locals.project_name
  ssm_ansible_password_arn = dependency.ssm.outputs.ssm_parameter_address.ssm_ansible_password.arn
  evm_policy_arn           = dependency.evm.outputs.aws_iam_policy_customer_arn
  evm_enabled              = local.features.locals.spryker_features.evm_enabled            
}
