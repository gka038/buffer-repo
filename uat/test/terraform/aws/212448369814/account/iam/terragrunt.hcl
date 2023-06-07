include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  iam     = read_terragrunt_config(find_in_parent_folders("config/iam/iam.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/iam/ecm?ref=development"
}

inputs = {
  project_owner = local.spryker.locals.customer_name
  users         = local.iam.locals.iam_users
}
