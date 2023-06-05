include {
  path = find_in_parent_folders()
}

locals {
  spryker       = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  features      = read_terragrunt_config(find_in_parent_folders("config/common/features.hcl"))
  repoconf      = read_terragrunt_config(find_in_parent_folders("config/deployment/repoconf.hcl"))
  codepipelines = read_terragrunt_config(find_in_parent_folders("config/deployment/codepipelines.hcl"))
}

skip = !local.features.locals.spryker_features.evm_enabled

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_codepipeline?ref=23_01.0"
}

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codebuild")

  
  mock_outputs = {
    codebuild_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "evm_lambda" {
  config_path = find_in_parent_folders("20-aws-based-infra/lambda/evm")

  
  mock_outputs = {
    lambda_env_vars_updater = "mock"
  }
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")

  
  mock_outputs = {
    ssm_evm_paths = {
      secret = { common = { internal = "mock", limited = "mock", public = "mock" }, app = { internal = "mock", limited = "mock", public = "mock" }, scheduler = { internal = "mock", limited = "mock", public = "mock" }, pipeline = { internal = "mock", limited = "mock", public = "mock" } }
      config = { common = { internal = "mock", limited = "mock", public = "mock" }, app = { internal = "mock", limited = "mock", public = "mock" }, scheduler = { internal = "mock", limited = "mock", public = "mock" }, pipeline = { internal = "mock", limited = "mock", public = "mock" } }
    }
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name       = local.spryker.locals.project_name
  pipeline_type      = local.codepipelines.locals.codepipelines_config.ecs_updater.pipeline_type
  autostart_pipeline = local.codepipelines.locals.codepipelines_config.ecs_updater.autostart_pipeline
  run_stages         = local.codepipelines.locals.codepipelines_config.ecs_updater.run_stages
  restart_services   = local.spryker.locals.services_to_restart
  service_role_arn   = dependency.iam_role.outputs.codebuild_role_arn
  spryker_repo_conf          = merge(
    local.repoconf.locals.spryker_repo_conf,
    { "github_token" : dependency.vault_secrets.outputs.spryker_secrets["github_token"] }
  )
  evm_config = {
    evm_enabled             = local.features.locals.spryker_features.evm_enabled
    lambda_env_vars_updater = dependency.evm_lambda.outputs.lambda_env_vars_updater
    ssm_evm_paths           = dependency.spryker_variables.outputs.ssm_evm_paths
  }
  sns_notification_topic_arn = null
}
