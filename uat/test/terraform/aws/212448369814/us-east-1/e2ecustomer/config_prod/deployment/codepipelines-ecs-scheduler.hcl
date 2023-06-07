locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  ecs_cluster     = read_terragrunt_config(find_in_parent_folders("config/spryker-services/ecs_cluster-scheduler.hcl"))
  spryker_service = read_terragrunt_config(find_in_parent_folders("config/spryker-services/ecs_service-scheduler.hcl"))

  codepipelines_config = {
    "destructive" = {
      pipeline_type      = "destructive_ecs"
      autostart_pipeline = false
      run_stages         = ["all"]
      scheduler_settings = {
        provider = "ECS"
        configuration = {
          ClusterName = "${local.ecs_cluster.locals.ecs_cluster_name}"
          ServiceName = "${local.ecs_cluster.locals.ecs_cluster_name}-${local.spryker_service.locals.service_name}"
          FileName    = "imagedefinitions-jenkins.json"
        }
      }
    }
    "normal" = {
      pipeline_type      = "normal_ecs"
      autostart_pipeline = false
      run_stages         = ["all"]
      scheduler_settings = {
        provider = "ECS"
        configuration = {
          ClusterName = "${local.ecs_cluster.locals.ecs_cluster_name}"
          ServiceName = "${local.ecs_cluster.locals.ecs_cluster_name}-${local.spryker_service.locals.service_name}"
          FileName    = "imagedefinitions-jenkins.json"
        }
      }
    }
    "build" = {
      pipeline_type      = "build_ecs"
      autostart_pipeline = false
      run_stages         = ["all"]
    }
    "ecs_updater" = {
      pipeline_type      = "ecs_updater"
      autostart_pipeline = false
      run_stages         = ["all"]
    }
    "scheduler_rollout" = {
      pipeline_type      = "scheduler_rollout_ecs"
      autostart_pipeline = false
      run_stages         = ["all"]
      scheduler_settings = {
        provider = "ECS"
        configuration = {
          ClusterName = "${local.ecs_cluster.locals.ecs_cluster_name}"
          ServiceName = "${local.ecs_cluster.locals.ecs_cluster_name}-${local.spryker_service.locals.service_name}"
          FileName    = "imagedefinitions-jenkins.json"
        }
      }
    }
    "maintenance_enable" = {
      pipeline_type      = "maintenance_enable"
      autostart_pipeline = false
      run_stages         = ["all"]
    }
    "maintenance_disable" = {
      pipeline_type      = "maintenance_disable"
      autostart_pipeline = false
      run_stages         = ["all"]
    },
    "e2e_tests" = {
      pipeline_type      = "e2e_tests"
      autostart_pipeline = false
      run_stages         = ["all"]
    }
  }
}
