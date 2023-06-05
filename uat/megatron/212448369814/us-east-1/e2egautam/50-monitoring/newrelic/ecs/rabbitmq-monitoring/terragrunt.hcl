include {
  path = find_in_parent_folders()
}

locals {
  spryker_service = read_terragrunt_config(find_in_parent_folders("config/monitoring/ecs_service-newrelic-rabbitmq-monitoring.hcl"))
  ecs_cluster     = read_terragrunt_config(find_in_parent_folders("config/spryker-services/ecs_cluster-primary.hcl"))
  newrelic        = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_ecs_service?ref=23_01.0"
}

skip = !local.newrelic.locals.newrelic_integration.enable_production_mode

dependency "iam_ecs_service" {
  config_path = find_in_parent_folders("00-initial-infra/iam/ecs-service")

  mock_outputs_merge_strategy_with_state = "deep_map_only"
  mock_outputs = {
    aws_iam_role_arn = {
      newrelic-rabbitmq-monitoring = "arn:aws:iam::123456789012:mock"
    }
  }
}

dependency "cert" {
  config_path = find_in_parent_folders("00-initial-infra/acm/main")

  
  mock_outputs = {
    cert_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  
  mock_outputs = {
    vpc_id                    = "mock"
    private_cmz_subnet_ids    = ["mock"]
    private_dmz_subnet_ids    = ["mock"]
    private_middle_subnet_ids = ["mock"]
  }
}

dependency "security_group" {
  config_path = find_in_parent_folders("10-network/security_groups/initial")

  
  mock_outputs = {
    security_group = "mock"
  }
}

dependency "external_alb" {
  config_path = find_in_parent_folders("10-network/lb/external_alb")

  
  mock_outputs = {
    alb_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "internal_nlb" {
  config_path = find_in_parent_folders("10-network/lb/internal_nlb")

  
  mock_outputs = {
    arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")

  
  mock_outputs = {
    environment_variables = {}
    discovered_ssm_params = {
      secret = { common = { internal = {}, limited = {}, public = {} }, app = { internal = {}, limited = {}, public = {} }, scheduler = { internal = {}, limited = {}, public = {} } }
      config = { common = { internal = {}, limited = {}, public = {} }, app = { internal = {}, limited = {}, public = {} }, scheduler = { internal = {}, limited = {}, public = {} } }
    }
  }
}

dependency "spryker_secrets" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-secrets/custom-secrets")

  
  mock_outputs = {
    ssm_parameter_address = {}
  }
}

dependency "ecs_cluster" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-cluster/ecs-cluster")

  
  mock_outputs = {
    ecs_cluster_id         = "mock"
    discovery_namespace_id = "mock"
    capacity_provider_name = "mock"
  }
}

inputs = {
  cluster_name                       = local.ecs_cluster.locals.ecs_cluster_name
  service_name                       = local.spryker_service.locals.service_name
  cluster_id                         = dependency.ecs_cluster.outputs.ecs_cluster_id
  network_mode                       = local.spryker_service.locals.network_mode
  cpu_limit                          = local.spryker_service.locals.cpu_limit
  memory_limit                       = local.spryker_service.locals.memory_limit
  execution_role_arn                 = local.newrelic.locals.newrelic_integration.enable_production_mode == true ? dependency.iam_ecs_service.outputs.aws_iam_role_arn[local.spryker_service.locals.service_name] : null
  discovery_namespace_id             = dependency.ecs_cluster.outputs.discovery_namespace_id
  vpc_id                             = dependency.vpc.outputs.vpc_id
  subnets                            = dependency.vpc.outputs.private_cmz_subnet_ids
  security_groups                    = [dependency.security_group.outputs.security_group]
  volumes                            = local.spryker_service.locals.volumes
  scheduling_strategy                = local.spryker_service.locals.scheduling_strategy
  desired_count                      = local.spryker_service.locals.desired_count
  deployment_maximum_percent         = local.spryker_service.locals.deployment_maximum_percent
  deployment_minimum_healthy_percent = local.spryker_service.locals.deployment_minimum_healthy_percent
  autoscaling_enabled                = local.spryker_service.locals.autoscaling_enabled
  autoscaling_min_capacity           = local.spryker_service.locals.autoscaling_min_capacity
  autoscaling_max_capacity           = local.spryker_service.locals.autoscaling_max_capacity
  capacity_provider                  = dependency.ecs_cluster.outputs.capacity_provider_name
  load_balancer_arn                  = local.spryker_service.locals.load_balancer_type == "internal" ? dependency.internal_nlb.outputs.arn : dependency.external_alb.outputs.alb_arn
  listener_mappings                  = local.spryker_service.locals.listener_mappings
  primary_cert_arn                   = dependency.cert.outputs.cert_arn
  secondary_cert_arns                = []
  deregistration_delay               = local.spryker_service.locals.deregistration_delay
  pid_mode                           = local.spryker_service.locals.pid_mode
  container_definitions = {
    name         = local.spryker_service.locals.container_definition.name
    image        = local.spryker_service.locals.container_definition.image == null ? "${dependency.ecr.outputs.repository_urls[local.spryker_service.locals.service_name]}:latest" : local.spryker_service.locals.container_definition.image
    mountPoints  = local.spryker_service.locals.container_definition.mountPoints
    portMappings = local.spryker_service.locals.container_definition.portMappings
    ulimits      = local.spryker_service.locals.container_definition.ulimits
    secrets = [
      for k, v in merge(
        dependency.spryker_secrets.outputs.ssm_parameter_address,
        dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.internal,
        dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.limited,
        dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.public,
        dependency.spryker_variables.outputs.discovered_ssm_params.secret.app.internal,
        dependency.spryker_variables.outputs.discovered_ssm_params.secret.app.limited,
        dependency.spryker_variables.outputs.discovered_ssm_params.secret.app.public
      ) : { "name" = k, "valueFrom" = v.arn }
    ]
    environment = [
      for k1, v1 in {
        for k, v in merge(
          lookup(dependency.spryker_variables.outputs.environment_variables, local.spryker_service.locals.service_name, {}),
          { for k, v in dependency.spryker_variables.outputs.discovered_ssm_params.config.common.internal : k => v.value },
          { for k, v in dependency.spryker_variables.outputs.discovered_ssm_params.config.common.limited : k => v.value },
          { for k, v in dependency.spryker_variables.outputs.discovered_ssm_params.config.common.public : k => v.value },
          { for k, v in dependency.spryker_variables.outputs.discovered_ssm_params.config.app.internal : k => v.value },
          { for k, v in dependency.spryker_variables.outputs.discovered_ssm_params.config.app.limited : k => v.value },
          { for k, v in dependency.spryker_variables.outputs.discovered_ssm_params.config.app.public : k => v.value }
          ) : k => v if !contains(keys(merge(
            dependency.spryker_secrets.outputs.ssm_parameter_address,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.public,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.app.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.app.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.app.public
      )), k) } : { name = k1, value = v1 }
    ]
  }
}