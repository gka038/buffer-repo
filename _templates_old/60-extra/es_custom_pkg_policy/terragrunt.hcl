include {
  path = find_in_parent_folders()
}

locals {
  es_custom_pkg_settings = read_terragrunt_config(find_in_parent_folders("config/extras/es_custom_pkg_policy.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/es/custom_pkg?ref=v9.0.0"
}

skip = !local.es_custom_pkg_settings.locals.enabled

inputs = {
  iam_user_list = toset(local.es_custom_pkg_settings.locals.iam_user_list)
}
