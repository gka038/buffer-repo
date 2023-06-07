include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  buddy   = read_terragrunt_config(find_in_parent_folders("config/buddy/buddy.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/buddy/buddy-workspace-setup?ref=feat/move-buddy-workspace"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("vault-secrets")
}


skip = !local.buddy.locals.common.buddy_enabled

inputs = {
  buddy_customer               = local.spryker.locals.customer_name
  buddy_customer_project       = local.spryker.locals.customer_project
  buddy_personal_token         = dependency.vault_secrets.outputs.spryker_secrets["buddy_personal_token"]
  buddy_github_token           = dependency.vault_secrets.outputs.spryker_secrets["buddy_github_token"]
  buddy_region                 = local.buddy.locals.common.buddy_region
  spryker_emails               = local.buddy.locals.workspace.spryker_admin_emails
  customer_admins              = local.buddy.locals.workspace.customer_admin_emails
  spryker_pipelines_branch     = local.buddy.locals.workspace.spryker_pipelines_branch
  projects_list                = local.buddy.locals.workspace.projects_list
  upgrader_schedule_in_minutes = local.buddy.locals.workspace.upgrader_delay
  newrelic_appname             = local.buddy.locals.workspace.newrelic_appname
  newrelic_license             = dependency.vault_secrets.outputs.spryker_secrets["newrelic_license_key"]
  newrelic_enabled             = local.buddy.locals.workspace.newrelic_enabled
  app_env                      = local.buddy.locals.workspace.app_env
}
