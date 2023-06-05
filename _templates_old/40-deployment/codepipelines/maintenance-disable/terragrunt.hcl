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
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_codepipeline?ref=v8.0.0"
}

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codebuild")
}

dependency "evm_lambda" {
  config_path = find_in_parent_folders("20-aws-based-infra/lambda/evm")
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")
}

inputs = {
  project_name               = local.spryker.locals.project_name
  pipeline_type              = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.maintenance_disable.pipeline_type : local.codepipelines_ec2.locals.codepipelines_config.maintenance_disable.pipeline_type
  autostart_pipeline         = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.maintenance_disable.autostart_pipeline : local.codepipelines_ec2.locals.codepipelines_config.maintenance_disable.autostart_pipeline
  run_stages                 = local.spryker.locals.scheduler_type == "ecs" ? local.codepipelines_ecs.locals.codepipelines_config.maintenance_disable.run_stages : local.codepipelines_ec2.locals.codepipelines_config.maintenance_disable.run_stages
  restart_services           = []
  service_role_arn           = dependency.iam_role.outputs.codebuild_role_arn
  spryker_repo_conf          = local.repoconf.locals.spryker_repo_conf
  sns_notification_topic_arn = null
  evm_config = {
    evm_enabled             = local.features.locals.spryker_features.evm_enabled
    lambda_env_vars_updater = dependency.evm_lambda.outputs.lambda_env_vars_updater
    ssm_evm_paths           = dependency.spryker_variables.outputs.ssm_evm_paths
  }
}
