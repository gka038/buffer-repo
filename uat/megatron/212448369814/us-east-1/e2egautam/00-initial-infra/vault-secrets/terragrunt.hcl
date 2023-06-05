include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

remote_state = {
  backend = "s3"
  config  = {
    disable_bucket_update = true
    region                = "eu-central-1"
    bucket                = "spryker-tf-states"
    dynamodb_table        = "spryker-tf-lock"
    key                   = "${local.spryker.locals.project_owner}/${local.spryker.locals.env_type}/${path_relative_to_include()}/terraform.tfstate"

  }
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/vault_secrets?ref=feat/vault-templates"
}

inputs = {
  project_owner        = local.spryker.locals.project_owner
  project_env          = local.spryker.locals.env_type
  customer_project     = local.spryker.locals.customer_project
  mount_point = "kv"
}

