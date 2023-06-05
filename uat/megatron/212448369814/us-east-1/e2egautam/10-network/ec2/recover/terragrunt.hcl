include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  network = read_terragrunt_config(find_in_parent_folders("config/network/bastion.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/ec2_recover?ref=23_01.0"
}

dependency "ec2" {
  config_path = find_in_parent_folders("10-network/ec2/bastion")

  
  mock_outputs = {
    instance_id = "mock"
  }
}


inputs = {
  project_name  = local.spryker.locals.project_name
  instance_name = local.network.locals.instance_name
  instance_id   = dependency.ec2.outputs.instance_id
}
