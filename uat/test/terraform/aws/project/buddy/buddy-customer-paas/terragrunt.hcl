include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  buddy   = read_terragrunt_config(find_in_parent_folders("config/buddy/buddy.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/buddy/buddy_customer_paas?ref=feat/buddy-customer-pipelines"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("vault-secrets")
}

dependency "buddy_workspace" {
  config_path = find_in_parent_folders("buddy/buddy-workspace")
}

skip = !local.buddy.locals.common.buddy_enabled

inputs = {
  customer_name                     = local.spryker.locals.customer_name
  customer_project                  = local.spryker.locals.customer_project
  buddy_personal_token              = dependency.vault_secrets.outputs.spryker_secrets["buddy_personal_token"]
  buddy_github_token                = dependency.vault_secrets.outputs.spryker_secrets["buddy_github_token"]
  buddy_region                      = local.buddy.locals.common.buddy_region
  integration_id                    = dependency.buddy_workspace.outputs.buddy_github_integration_id
  repository_path                   = local.buddy.locals.customer_paas.repository_path
  buddy_workspace_domain            = dependency.buddy_workspace.outputs.buddy_workspace_domain
  buddy_customer_admin_role_id      = dependency.buddy_workspace.outputs.buddy_customer_admin_role_id
  buddy_customer_ro_role_id         = dependency.buddy_workspace.outputs.buddy_customer_ro_role_id
  buddy_admin_group_id              = dependency.buddy_workspace.outputs.buddy_admin_group_id
  buddy_dev_group_id                = dependency.buddy_workspace.outputs.buddy_dev_group_id
  remote_pipelines_project_name     = dependency.buddy_workspace.outputs.buddy_project_spryker_pipelines
  remote_pipelines_project_branch   = local.buddy.locals.customer_paas.remote_pipelines_project_branch
  remote_pipelines_project_path     = local.buddy.locals.customer_paas.remote_pipelines_project_path
  spryker_infra_validator_image     = local.buddy.locals.customer_paas.spryker_infra_validator_image
  spryker_infra_validator_image_tag = local.buddy.locals.customer_paas.spryker_infra_validator_image_tag
  spryker_infra_generator_image     = local.buddy.locals.customer_paas.spryker_infra_generator_image
  spryker_infra_generator_image_tag = local.buddy.locals.customer_paas.spryker_infra_generator_image_tag
  cda_buffer_repo                   = local.buddy.locals.customer_paas.cda_buffer_repo
  cda_buffer_repo_branch            = local.buddy.locals.customer_paas.cda_buffer_repo_branch
}
