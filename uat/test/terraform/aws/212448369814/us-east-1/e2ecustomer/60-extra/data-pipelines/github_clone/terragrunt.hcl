include {
  path = find_in_parent_folders()
}

locals {
  gmv_cc_shared = read_terragrunt_config(find_in_parent_folders("config/extras/gmv_and_composer_shared.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/github_clone?ref=23_02.0"
}

skip = !local.gmv_cc_shared.locals.gmv_enabled

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  token        = dependency.vault_secrets.outputs.spryker_secrets["gmv_and_composer_content_github_token"]
  repo_address = local.gmv_cc_shared.locals.gmv_and_composer_content_repo
}
