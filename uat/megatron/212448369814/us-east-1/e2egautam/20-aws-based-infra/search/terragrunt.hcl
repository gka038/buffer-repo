include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/search.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/search?ref=23_01.0"
}

dependency "kms_key" {
  config_path = find_in_parent_folders("00-initial-infra/kms/search")

  
  mock_outputs = {
    kms_key_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "service-linked-roles" {
  config_path  = find_in_parent_folders("00-initial-infra/iam/service-linked-roles")
  skip_outputs = true
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  
  mock_outputs = {
    vpc_id                    = "mock"
    private_middle_subnet_ids = ["mock"]
  }
}

dependency "sg" {
  config_path = find_in_parent_folders("10-network/security_groups/initial")

  
  mock_outputs = {
    security_group = "mock"
  }
}

inputs = {
  project_name       = local.spryker.locals.project_name
  kms_key_arn        = dependency.kms_key.outputs.kms_key_arn
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnets            = dependency.vpc.outputs.private_middle_subnet_ids
  vpc_security_group = dependency.sg.outputs.security_group
  settings           = local.aws-based-infra.locals.settings
}
