include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  initial-infra = read_terragrunt_config(find_in_parent_folders("config/initial-infra/ssm.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/spryker_secrets_ssm?ref=23_02.0"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  project_name    = local.spryker.locals.project_name
  parameters_type = local.initial-infra.locals.parameters_type
  ssm_prefix      = local.initial-infra.locals.ssm_prefix
  spryker_secrets = {
    ssm_ansible_password = dependency.vault_secrets.outputs.spryker_secrets["ssm_ansible_password"]
  }
}
