locals {
  cluster_primary = read_terragrunt_config(find_in_parent_folders("config/spryker-services/ecs_cluster-primary.hcl"))

  # /02-aws-based-infra/lambda/backup-notifier
  backup-notifier = {
    recipient = "devops@spryker.com"
  }
  # /20-aws-based-infra/lambda/certificate-expiration-date
  certificate-expiration-date = {
    recipient      = "devops@spryker.com"
    threshold_days = 30
  }
  # /20-aws-based-infra/lambda/asg_scaling
  asg_scaling_enabled  = false
  downscaling_schedule = "cron(00 20 ? * * *)"
  upscaling_schedule   = "cron(50 08 ? * * *)"
  asg_config = {
    "${local.cluster_primary.locals.ecs_cluster_name}-asg-scale-up" = {
      desired = local.cluster_primary.locals.autoscaling_min_size
      min     = local.cluster_primary.locals.autoscaling_min_size
      max     = local.cluster_primary.locals.autoscaling_max_size
    }
    "${local.cluster_primary.locals.ecs_cluster_name}-asg-scale-down" = {
      desired = 0
      min     = 0
      max     = 0
    }
  }
  # /20-aws-based-infra/lambda/rds
  rds_stop_start_enabled = false
  stop_schedule          = "cron(00 20 ? * * *)"
  start_schedule         = "cron(00 09 ? * * *)"
  # /20-aws-based-infra/lambda/rds/jenkins
  event_id = "RDS-EVENT-0088" # Event ID(DB instance started), based on which "customer-env-scheduler-resume" lambda will be triggered
}
