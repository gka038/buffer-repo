include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  features          = read_terragrunt_config(find_in_parent_folders("config/common/features.hcl"))
  repoconf          = read_terragrunt_config(find_in_parent_folders("config/deployment/repoconf.hcl"))
  codepipelines_ec2 = read_terragrunt_config(find_in_parent_folders("config/deployment/codepipelines.hcl"))
  codepipelines_ecs = read_terragrunt_config(find_in_parent_folders("config/deployment/codepipelines-ecs-scheduler.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/aws_codepipeline?ref=development"
}

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codebuild")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    codebuild_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "evm_lambda" {
  config_path = find_in_parent_folders("20-aws-based-infra/lambda/evm")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    lambda_env_vars_updater = "mock"
  }
}

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    internal_s3_bucket_name = "mock"
  }
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_evm_paths = {
      secret = { common = { internal = "mock", limited = "mock", public = "mock" }, app = { internal = "mock", limited = "mock", public = "mock" }, scheduler = { internal = "mock", limited = "mock", public = "mock" }, pipeline = { internal = "mock", limited = "mock", public = "mock" } }
      config = { common = { internal = "mock", limited = "mock", public = "mock" }, app = { internal = "mock", limited = "mock", public = "mock" }, scheduler = { internal = "mock", limited = "mock", public = "mock" }, pipeline = { internal = "mock", limited = "mock", public = "mock" } }
    }
  }
}

dependency "codedeploy" {
  config_path  = find_in_parent_folders("40-deployment/codedeploy-jenkins")
  skip_outputs = true
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name       = local.spryker.locals.project_name
  pipeline_type      = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.scheduler_rollout.pipeline_type : local.codepipelines_ec2.locals.codepipelines_config.scheduler_rollout.pipeline_type
  autostart_pipeline = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.scheduler_rollout.autostart_pipeline : local.codepipelines_ec2.locals.codepipelines_config.scheduler_rollout.autostart_pipeline
  run_stages         = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.scheduler_rollout.run_stages : local.codepipelines_ec2.locals.codepipelines_config.scheduler_rollout.run_stages
  restart_services   = local.spryker.locals.spryker_services
  service_role_arn   = dependency.iam_role.outputs.codebuild_role_arn
  spryker_repo_conf          = merge(
    local.repoconf.locals.spryker_repo_conf,
    { "github_token" : dependency.vault_secrets.outputs.spryker_secrets["github_token"] }
  )
  scheduler_settings = {
    provider      = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.scheduler_rollout.scheduler_settings.provider : local.codepipelines_ec2.locals.codepipelines_config.scheduler_rollout.scheduler_settings.provider
    configuration = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.scheduler_rollout.scheduler_settings.configuration : local.codepipelines_ec2.locals.codepipelines_config.scheduler_rollout.scheduler_settings.configuration
  }
  evm_config = {
    evm_enabled             = local.features.locals.spryker_features.evm_enabled
    lambda_env_vars_updater = dependency.evm_lambda.outputs.lambda_env_vars_updater
    ssm_evm_paths           = dependency.spryker_variables.outputs.ssm_evm_paths
  }
  sns_notification_topic_arn = null
  s3_bucket_name            = dependency.s3.outputs.internal_s3_bucket_name
}
