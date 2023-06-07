include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/lambda.hcl"))
  ecs_cluster     = read_terragrunt_config(find_in_parent_folders("config/spryker-services/ecs_cluster-scheduler.hcl"))
  sdk_vars        = read_terragrunt_config(find_in_parent_folders("environment.tf"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/lambda/rds/stop?ref=23_02.0"
}

skip = !local.aws-based-infra.locals.rds_stop_start_enabled

dependency "rds" {
  config_path = find_in_parent_folders("00-initial-infra/iam/rds")
}

inputs = {
  project_name        = local.spryker.locals.project_name
  lambda_iam_role_arn = dependency.rds.outputs.rds_lambda_role_arn
  stop_schedule       = local.aws-based-infra.locals.stop_schedule
  scheduler_name      = "${local.ecs_cluster.locals.ecs_cluster_name}-ecs-autoscaled"
  active_stores       = lower(local.sdk_vars.locals.spryker_environment.yves.SPRYKER_ACTIVE_STORES)
}
