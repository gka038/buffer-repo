locals {
  secrets                       = read_terragrunt_config(find_in_parent_folders("secrets/deployment/codepipeline-notifications.hcl"))
  opsgenie_api_key              = local.secrets.locals.opsgenie_aws_codepipeline_failure
  enable_destructive_deployment = true
  auto_deploy_enabled           = false
}
