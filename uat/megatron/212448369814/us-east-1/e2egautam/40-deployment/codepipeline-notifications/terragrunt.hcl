include {
  path = find_in_parent_folders()
}

locals {
  spryker                    = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codepipeline_notifications = read_terragrunt_config(find_in_parent_folders("config/deployment/codepipeline-notifications.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/codepipeline_notifications?ref=23_01.0"
}

dependency "lambda" {
  config_path = find_in_parent_folders("20-aws-based-infra/lambda/pipeline-nr-notifier")

  
  mock_outputs = {
    newrelic_lambda_notificator_arn           = "arn:aws:iam::123456789012:mock"
    newrelic_lambda_notificator_function_name = "mock"
  }
}

dependency "codepipelines-destructive" {
  config_path = find_in_parent_folders("40-deployment/codepipelines/destructive")

  
  mock_outputs = {
    codepipeline_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "codepipelines-normal" {
  config_path = find_in_parent_folders("40-deployment/codepipelines/normal")

  
  mock_outputs = {
    codepipeline_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "codepipelines-build" {
  config_path = find_in_parent_folders("40-deployment/codepipelines/build")

  
  mock_outputs = {
    codepipeline_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "codepipelines-scheduler-rollout" {
  config_path = find_in_parent_folders("40-deployment/codepipelines/scheduler-rollout")

  
  mock_outputs = {
    codepipeline_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  project_name = local.spryker.locals.project_name
  pipeline_arns = [
    dependency.codepipelines-normal.outputs.codepipeline_arn,
    dependency.codepipelines-scheduler-rollout.outputs.codepipeline_arn
  ]
  destructive_pipeline_arn                  = dependency.codepipelines-destructive.outputs.codepipeline_arn
  build_pipeline_arn                        = dependency.codepipelines-build.outputs.codepipeline_arn
  opsgenie_api_key                          = dependency.vault_secrets.outputs.spryker_secrets["opsgenie_aws_codepipeline_notifications_api_key"]
  newrelic_lambda_notificator_arn           = dependency.lambda.outputs.newrelic_lambda_notificator_arn
  newrelic_lambda_notificator_function_name = dependency.lambda.outputs.newrelic_lambda_notificator_function_name
  enable_destructive_deployment             = local.codepipeline_notifications.locals.enable_destructive_deployment
  auto_deploy_enabled                       = local.codepipeline_notifications.locals.auto_deploy_enabled
}
