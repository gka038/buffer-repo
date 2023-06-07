include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codebuild-project = read_terragrunt_config(find_in_parent_folders("config/deployment/codebuild.hcl"))
  source_template = {
    ec2 = "codebuild_prepare_scheduler_buildspec.yml.tmpl"
    ecs = "codebuild_prepare_scheduler_ecs_buildspec.yml.tmpl"
  }
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/aws_codebuild?ref=23_02.0"
}

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codebuild")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    codebuild_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "dockerhub_creds" {
  config_path  = find_in_parent_folders("00-initial-infra/secrets-manager/dockerhub-creds")
  skip_outputs = true
}

dependency "vpc" {
  config_path  = find_in_parent_folders("10-network/vpc")
  skip_outputs = true
}

dependency "ecr" {
  config_path = find_in_parent_folders("20-aws-based-infra/ecr")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    repository_urls = { boffice = "mock", jenkins = "mock" }
  }
}

dependency "security_group" {
  config_path = find_in_parent_folders("10-network/security_groups/codebuild")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    security_group = "mock"
  }
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    environment_variables = { boffice = {}, jenkins = {} }
    discovered_ssm_params = {
      secret = { common = { internal = {}, limited = {}, public = {} }, app = { internal = {}, limited = {}, public = {} }, scheduler = { internal = {}, limited = {}, public = {} }, pipeline = { internal = {}, limited = {}, public = {} } }
      config = { common = { internal = {}, limited = {}, public = {} }, app = { internal = {}, limited = {}, public = {} }, scheduler = { internal = {}, limited = {}, public = {} }, pipeline = { internal = {}, limited = {}, public = {} } }
    }
    ssm_evm_paths = {
      secret = { common = { internal = "mock", limited = "mock", public = "mock" }, app = { internal = "mock", limited = "mock", public = "mock" }, scheduler = { internal = "mock", limited = "mock", public = "mock" } }
      config = { common = { internal = "mock", limited = "mock", public = "mock" }, app = { internal = "mock", limited = "mock", public = "mock" }, scheduler = { internal = "mock", limited = "mock", public = "mock" } }
    }
  }
}

dependency "spryker_secrets_custom" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-secrets/custom-secrets")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_parameter_address = {}
  }
}

dependency "spryker_secrets_base" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-secrets/base-task-definition")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    ssm_parameter_address = {}
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  codebuild_projects_variables = {
    project_name                   = local.spryker.locals.project_name
    ssm_custom_secrets_path_prefix = "/${local.spryker.locals.project_name}/custom-secrets"
    SSM_PATHS = join(" ", concat(
      values(dependency.spryker_variables.outputs.ssm_evm_paths.config.common),
      values(dependency.spryker_variables.outputs.ssm_evm_paths.config.scheduler),
      values(dependency.spryker_variables.outputs.ssm_evm_paths.secret.common),
      values(dependency.spryker_variables.outputs.ssm_evm_paths.secret.scheduler)
    ))
  }

  codebuild_projects_config = {
    "scheduler" = {
      namebase             = local.codebuild-project.locals.codebuild_projects_config.scheduler.namebase
      description          = local.codebuild-project.locals.codebuild_projects_config.scheduler.description
      build_timeout        = local.codebuild-project.locals.codebuild_projects_config.scheduler.build_timeout
      service_role_arn     = dependency.iam_role.outputs.codebuild_role_arn
      artifacts            = local.codebuild-project.locals.codebuild_projects_config.scheduler.artifacts
      secondary_artifact   = null
      secondary_sources    = null
      cache_config         = local.codebuild-project.locals.codebuild_projects_config.scheduler.cache_config
      source_template      = local.source_template[local.spryker.locals.scheduler_type]
      source_template_vars = local.codebuild-project.locals.codebuild_projects_config.scheduler.source_template_vars
      source_type          = local.codebuild-project.locals.codebuild_projects_config.scheduler.source_type
      environment_config = {
        compute_type                = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.compute_type
        image                       = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.image
        image_pull_credentials_type = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.image_pull_credentials_type
        type                        = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.type
        privileged_mode             = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.privileged_mode
        registry_credential         = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.registry_credential
        environment_variables = merge({
          ENVIRONMENT_VARIABLES = {
            value = base64gzip(jsonencode({
              "ENVIRONMENT_VARIABLES" = merge(
                try(dependency.spryker_variables.outputs.environment_variables["boffice"], dependency.spryker_variables.outputs.environment_variables["zed"]),
                dependency.spryker_variables.outputs.environment_variables["jenkins"],
                { for k, v in dependency.spryker_secrets_base.outputs.ssm_parameter_address : k => v.value },
                { for k, v in dependency.spryker_secrets_custom.outputs.ssm_parameter_address : k => v.value },
                { for k, v in merge(
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.common.internal,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.common.limited,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.common.public,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.pipeline.internal,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.pipeline.limited,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.pipeline.public,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.scheduler.internal,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.scheduler.limited,
                  dependency.spryker_variables.outputs.discovered_ssm_params.config.scheduler.public,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.internal,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.limited,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.public,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.internal,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.limited,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.public,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.scheduler.internal,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.scheduler.limited,
                  dependency.spryker_variables.outputs.discovered_ssm_params.secret.scheduler.public
                ) : k => v.value }
              )
              AWS_REGION               = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.AWS_REGION.value}"
              PROJECT_NAME             = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.PROJECT_NAME.value}"
              JENKINS_IMAGE            = "${dependency.ecr.outputs.repository_urls["jenkins"]}"
              GRACEFUL_SHUTDOWN_PERIOD = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.GRACEFUL_SHUTDOWN_PERIOD.value}"
              SFTP_EFS_MOUNT_POINT     = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.SFTP_EFS_MOUNT_POINT.value}"
              NEWRELIC_INTEGRATION     = tostring(local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.NEWRELIC_INTEGRATION.value)
              NRIA_LICENSE_KEY         = "${dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_license_key"]}"
          })), type = "PLAINTEXT" } },
          {
            AWS_REGION               = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.AWS_REGION
            PROJECT_NAME             = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.PROJECT_NAME
            JENKINS_IMAGE            = { value = "${dependency.ecr.outputs.repository_urls["jenkins"]}", type = "PLAINTEXT" }
            GRACEFUL_SHUTDOWN_PERIOD = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.GRACEFUL_SHUTDOWN_PERIOD
            NEWRELIC_INTEGRATION     = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.NEWRELIC_INTEGRATION
            NRIA_LICENSE_KEY         = { value = "${dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_license_key"]}", type = "PLAINTEXT" }
            SFTP_EFS_MOUNT_POINT     = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.SFTP_EFS_MOUNT_POINT
        })
      }
      vpc_config = null
      tags       = {}
    }
  }
}
