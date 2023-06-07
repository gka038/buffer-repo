include {
  path = find_in_parent_folders()
}

locals {
  spryker-common      = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  spryker-features    = read_terragrunt_config(find_in_parent_folders("config/common/features.hcl"))
  spryker-environment = read_terragrunt_config(find_in_parent_folders("config/spryker-services/spryker-environment.hcl"))
  features_configs = {
    SPRYKER_FEATURES = jsonencode({
      DB      = local.spryker-features.locals.spryker_features.multidb_enabled ? 1 : 0,
      ENV_VAR = local.spryker-features.locals.spryker_features.evm_enabled ? 1 : 0
    }),
    SPRYKER_PAAS_SERVICES = jsonencode({
      version   = "1.0",
      databases = []
    })
    SPRYKER_MAINTENANCE_MODE_ENABLED = local.spryker-features.locals.spryker_features.maintenance_mode_enabled ? 1 : 0
  }
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/spryker_secrets_ssm?ref=23_02.0"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  project_name    = local.spryker-common.locals.project_name
  ssm_prefix      = local.spryker-environment.locals.custom-secrets.ssm_prefix
  parameters_type = local.spryker-environment.locals.custom-secrets.parameters_type
  spryker_secrets = merge(dependency.vault_secrets.outputs.spryker_secrets["spryker_secrets"], local.features_configs)
}
