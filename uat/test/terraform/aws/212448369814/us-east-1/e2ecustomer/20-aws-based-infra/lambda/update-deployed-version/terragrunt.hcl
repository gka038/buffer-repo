include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/lambda/update_deployed_version?ref=23_02.0"
}

dependency "iam" {
  config_path = find_in_parent_folders("00-initial-infra/iam/update-deployed-version")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    iam_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

inputs = {
  project_name = local.spryker.locals.project_name
  iam_role_arn = dependency.iam.outputs.iam_role_arn
}
