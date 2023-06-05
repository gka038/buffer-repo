include {
  path = find_in_parent_folders()
}

locals {
  spryker      = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  buddy        = read_terragrunt_config(find_in_parent_folders("config/extras/buddy.hcl"))
  buddy_secret = read_terragrunt_config(find_in_parent_folders("secrets/extras/buddy.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/buddy/buddy-stage?ref=v9.0.0"
}

skip = !local.buddy.locals.enabled

dependency "iam_buddy" {
  config_path = find_in_parent_folders("00-initial-infra/iam/buddy")

  mock_outputs = {
    aws_iam_role_buddy_role_arn = ""
  }
}

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
  buddy_customer_environment_name = local.spryker.locals.project_name
  buddy_customer_environment_type = local.spryker.locals.env_type
  buddy_personal_token            = local.buddy_secret.locals.buddy_personal_token
  buddy_region                    = local.buddy.locals.buddy_region
  buddy_github_user               = local.buddy.locals.buddy_github_user
  buddy_github_token              = local.buddy_secret.locals.buddy_github_token
  repository_path                 = local.buddy.locals.repository_path
  repository_branch_buddy         = local.buddy.locals.repository_branch_buddy
  amazon_region                   = local.spryker.locals.region
  auto_deploy                     = local.buddy.locals.auto_deploy
  spryker_static_apps             = local.buddy.locals.spryker_static_apps
  spryker_pipelines_branch        = local.buddy.locals.spryker_pipelines_branch
  is_production                   = local.buddy.locals.is_production
  iam_role_buddy_role_arn         = dependency.iam_buddy.outputs.aws_iam_role_buddy_role_arn
  buddy_domain                    = dependency.buddy_workspace.outputs.buddy_workspace_domain
  buddy_github_integration_id     = dependency.buddy_workspace.outputs.buddy_github_integration_id
  buddy_admin_group_id            = dependency.buddy_workspace.outputs.buddy_admin_group_id
  buddy_dev_group_id              = dependency.buddy_workspace.outputs.buddy_dev_group_id
  buddy_admin_role_id             = dependency.buddy_workspace.outputs.buddy_customer_admin_role_id
  buddy_dev_role_id               = dependency.buddy_workspace.outputs.buddy_customer_ro_role_id
  remote_project_name_pipeline    = dependency.buddy_workspace.outputs.buddy_project_spryker_pipelines
  remote_project_name_upgrader    = dependency.buddy_workspace.outputs.spryker_upgrader
}
