locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codepipelines_config = {
    "destructive" = {
      pipeline_type      = "destructive"
      autostart_pipeline = false
      run_stages         = ["all"]
      scheduler_settings = {
        provider = "CodeDeploy"
        configuration = {
          ApplicationName     = "${local.spryker.locals.project_name}-spryker_scheduler"
          DeploymentGroupName = substr("${local.spryker.locals.project_name}-scheduler-deployment-group", 0, 32)
        }
      }
    }
    "normal" = {
      pipeline_type      = "normal"
      autostart_pipeline = false
      run_stages         = ["all"]
      scheduler_settings = {
        provider = "CodeDeploy"
        configuration = {
          ApplicationName     = "${local.spryker.locals.project_name}-spryker_scheduler"
          DeploymentGroupName = substr("${local.spryker.locals.project_name}-scheduler-deployment-group", 0, 32)
        }
      }
    }
    "build" = {
      pipeline_type      = "build"
      autostart_pipeline = false
      run_stages         = ["all"]
    }
    "ecs_updater" = {
      pipeline_type      = "ecs_updater"
      autostart_pipeline = false
      run_stages         = ["all"]
    }
    "scheduler_rollout" = {
      pipeline_type      = "scheduler_rollout"
      autostart_pipeline = false
      run_stages         = ["all"]
      scheduler_settings = {
        provider = "CodeDeploy"
        configuration = {
          ApplicationName     = "${local.spryker.locals.project_name}-spryker_scheduler"
          DeploymentGroupName = substr("${local.spryker.locals.project_name}-scheduler-deployment-group", 0, 32)
        }
      }
    }
    "maintenance_enable" = {
      pipeline_type      = "maintenance_enable"
      autostart_pipeline = false
      run_stages    = ["all"]
    }
    "maintenance_disable" = {
      pipeline_type      = "maintenance_disable"
      autostart_pipeline = false
      run_stages    = ["all"]
    }
  }
}
