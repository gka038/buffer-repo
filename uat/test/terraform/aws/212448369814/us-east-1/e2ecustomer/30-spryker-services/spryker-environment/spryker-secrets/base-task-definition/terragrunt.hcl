include {
  path = find_in_parent_folders()
}

locals {
  spryker          = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  spryker-services = read_terragrunt_config(find_in_parent_folders("config/spryker-services/spryker-environment.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/aws_ssm_parameter/base_task_definition?ref=23_02.0"
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    environment_variables = {}
  }
}

inputs = {
  project_name    = local.spryker.locals.project_name
  ssm_prefix      = local.spryker-services.locals.base-task-definition.ssm_prefix
  parameters_type = local.spryker-services.locals.base-task-definition.parameters_type
  spryker_secrets = { for k, v in try(dependency.spryker_variables.outputs.environment_variables["boffice"], dependency.spryker_variables.outputs.environment_variables["zed"], {}) : k => v }
}
