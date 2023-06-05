include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  buddy   = read_terragrunt_config(find_in_parent_folders("config/extras/buddy.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/iam/buddy?ref=v9.0.0"
}

skip = !local.buddy.locals.enabled

inputs = {
  buddy_customer = local.spryker.locals.project_name
}
