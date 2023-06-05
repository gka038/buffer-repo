include {
  path = find_in_parent_folders()
}

locals {
  spryker    = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codedeploy = read_terragrunt_config(find_in_parent_folders("config/deployment/codedeploy.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_codedeploy?ref=23_01.0"
}

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codedeploy")

  
  mock_outputs = {
    codedeploy_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

inputs = {
  project_name              = local.spryker.locals.project_name
  service_role_arn          = dependency.iam_role.outputs.codedeploy_role_arn
  jenkins_target_group_name = "${local.spryker.locals.project_name}-scheduler"
  jenkins_name              = "${local.spryker.locals.project_name}-scheduler"
  logs_expire               = local.codedeploy.locals.logs_expire
}
