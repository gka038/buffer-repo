include {
  path = find_in_parent_folders()
}

locals {
  spryker    = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  deployment = read_terragrunt_config(find_in_parent_folders("config/deployment/codebuild.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/spryker_secrets_manager?ref=23_02.0"
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  project_name = local.spryker.locals.project_name
  secret_name  = local.deployment.locals.secret_name
  secret_contents = {
    username = "${local.deployment.locals.dockerhub_username}"
    password = "${dependency.vault_secrets.outputs.spryker_secrets["dockerhub_password"]}"
  }
}
