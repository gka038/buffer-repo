include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  buddy   = read_terragrunt_config(find_in_parent_folders("config/extras/buddy.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/buddy/buddy_paas?ref=development"
}

skip = !local.buddy.locals.enabled

dependency "buddy_workspace" {
  config_path = "/${get_parent_terragrunt_dir()}/../buddy-workspace/workspace"

  mock_outputs = {
    buddy_workspace_domain          = local.spryker.locals.project_owner
    buddy_project_spryker_pipelines = "spryker-pipelines"
    spryker_upgrader                = "spryker-upgrade-service"
    buddy_github_integration_id     = ""
    buddy_admin_group_id            = 0
    buddy_dev_group_id              = 0
    buddy_customer_admin_role_id    = 0
    buddy_customer_ro_role_id       = 0
  }
}

inputs = {
  buddy_admin_group_id              = dependency.buddy_workspace.outputs.buddy_admin_group_id
  buddy_customer_admin_role_id      = dependency.buddy_workspace.outputs.buddy_customer_admin_role_id
  buddy_dev_group_id                = dependency.buddy_workspace.outputs.buddy_dev_group_id
  buddy_customer_ro_role_id         = dependency.buddy_workspace.outputs.buddy_customer_ro_role_id
  buddy_workspace_domain            = dependency.buddy_workspace.outputs.buddy_workspace_domain
  buddy_github_integration_id       = dependency.buddy_workspace.outputs.buddy_github_integration_id
  buddy_github_token                = local.buddy.locals.buddy_github_token
  buddy_personal_token              = local.buddy.locals.buddy_personal_token
  buddy_project_spryker_pipelines   = dependency.buddy_workspace.outputs.buddy_project_spryker_pipelines
  buddy_region                      = local.buddy.locals.buddy_region
  customer_name                     = local.spryker.locals.project_owner
  customer_projects                 = local.buddy.locals.buddy-paas.customer_projects
  enable_paas                       = local.buddy.locals.buddy-paas.enable_paas
  repository_path                   = local.buddy.locals.repository_path
  remote_pipelines_path             = local.buddy.locals.remote_pipelines_path
  spryker_pipelines_branch          = local.buddy.locals.spryker_pipelines_branch
  spryker_infra_validator_image     = local.buddy.locals.buddy-paas.spryker_infra_validator_image
  spryker_infra_validator_image_tag = local.buddy.locals.buddy-paas.spryker_infra_validator_image_tag
  spryker_infra_generator_image     = local.buddy.locals.buddy-paas.spryker_infra_generator_image
  spryker_infra_generator_image_tag = local.buddy.locals.buddy-paas.spryker_infra_generator_image_tag
}
