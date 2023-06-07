include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codebuild-project = read_terragrunt_config(find_in_parent_folders("config/deployment/codebuild.hcl"))
  sdk_vars          = read_terragrunt_config(find_in_parent_folders("environment.tf"))
  customer_name     = local.spryker.locals.project_owner
  customer_env      = local.spryker.locals.env_type
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

dependency "aws_data" {
  config_path = find_in_parent_folders("00-initial-infra/aws-data")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    account_id = "123456789012"
  }
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    vpc_id                 = "mock"
    private_cmz_subnet_ids = ["mock"]
  }
}

dependency "security_group" {
  config_path = find_in_parent_folders("10-network/security_groups/codebuild")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    security_group = "mock"
  }
}

dependency "ecr" {
  config_path = find_in_parent_folders("20-aws-based-infra/ecr")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    repository_urls = { jenkins = "mock" }
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

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    codebuild_s3_bucket_name = "mock"
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  codebuild_projects_variables = {
    project_name                   = local.spryker.locals.project_name
    project_owner                  = local.spryker.locals.project_owner
    checked_services               = jsonencode(([for k in keys(local.sdk_vars.locals.spryker_environment) : lower(k) if k != "e2e"]))
    services                       = jsonencode(local.spryker.locals.spryker_ecr_repos)
    enable_jenkins_on_ecs          = local.spryker.locals.scheduler_type == "ecs" ? true : false
    docker_registry_type           = local.codebuild-project.locals.docker_registry_type
    aws_account_id                 = dependency.aws_data.outputs.account_id
    hash_id                        = local.codebuild-project.locals.hash_id
    ssm_custom_secrets_path_prefix = "/${local.spryker.locals.project_name}/custom-secrets"
    deploy_file                    = local.codebuild-project.locals.deploy_file
    SSM_PATHS = join(" ", concat(
      values(dependency.spryker_variables.outputs.ssm_evm_paths.config.common),
      values(dependency.spryker_variables.outputs.ssm_evm_paths.config.scheduler),
      values(dependency.spryker_variables.outputs.ssm_evm_paths.secret.common),
      values(dependency.spryker_variables.outputs.ssm_evm_paths.secret.scheduler)
    ))

  }
  codebuild_projects_config = {
    "app_build" = {
      namebase          = local.codebuild-project.locals.codebuild_projects_config.app_build.namebase
      description       = local.codebuild-project.locals.codebuild_projects_config.app_build.description
      build_timeout     = local.codebuild-project.locals.codebuild_projects_config.app_build.build_timeout
      service_role_arn  = dependency.iam_role.outputs.codebuild_role_arn
      artifacts         = local.codebuild-project.locals.codebuild_projects_config.app_build.artifacts
      secondary_sources = null
      secondary_artifact = {
        name                = local.codebuild-project.locals.codebuild_projects_config.app_build.secondary_artifact.name
        type                = local.codebuild-project.locals.codebuild_projects_config.app_build.secondary_artifact.type
        artifact_identifier = local.codebuild-project.locals.codebuild_projects_config.app_build.secondary_artifact.artifact_identifier
        path                = local.codebuild-project.locals.codebuild_projects_config.app_build.secondary_artifact.path
        packaging           = local.codebuild-project.locals.codebuild_projects_config.app_build.secondary_artifact.packaging
        location            = dependency.s3.outputs.internal_s3_bucket_name
      }
      cache_config         = local.codebuild-project.locals.codebuild_projects_config.app_build.cache_config
      source_template      = local.codebuild-project.locals.codebuild_projects_config.app_build.source_template
      source_template_vars = local.codebuild-project.locals.codebuild_projects_config.app_build.source_template_vars
      source_type          = local.codebuild-project.locals.codebuild_projects_config.app_build.source_type
      environment_config = {
        compute_type                = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.compute_type
        image                       = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.image
        image_pull_credentials_type = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.image_pull_credentials_type
        type                        = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.type
        privileged_mode             = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.privileged_mode
        registry_credential         = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.registry_credential
        environment_variables = merge({
          ENVIRONMENT_VARIABLES = {
            value = base64gzip(jsonencode({
              "ENVIRONMENT_VARIABLES" = merge(
                try(dependency.spryker_variables.outputs.environment_variables["boffice"], dependency.spryker_variables.outputs.environment_variables["zed"]),
                dependency.spryker_variables.outputs.environment_variables["jenkins"],
                { for k, v in dependency.spryker_secrets_base.outputs.ssm_parameter_address : k => v.value },
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
              AWS_REGION           = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.AWS_REGION.value}"
              PROJECT_NAME         = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.PROJECT_NAME.value}"
              SFTP_EFS_MOUNT_POINT = "${local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.SFTP_EFS_MOUNT_POINT.value}"
              NEWRELIC_INTEGRATION = tostring(local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.NEWRELIC_INTEGRATION.value)
              NRIA_LICENSE_KEY     = "${dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_license_key"]}"
          })), type = "PLAINTEXT" } },
          { for k, v in dependency.spryker_secrets_base.outputs.ssm_parameter_address : k => { value = v.name, type = "PARAMETER_STORE" } if can(regex(dependency.spryker_variables.outputs.regex_sensitive, k)) && !can(regex(dependency.spryker_variables.outputs.regex_nonsensitive, v.value)) },
          { for k, v in dependency.spryker_secrets_base.outputs.ssm_parameter_address : k => { value = v.value, type = "PLAINTEXT" } if !can(regex(dependency.spryker_variables.outputs.regex_sensitive, k)) || can(regex(dependency.spryker_variables.outputs.regex_nonsensitive, v.value)) },
          { for k, v in merge(
            dependency.spryker_variables.outputs.discovered_ssm_params.config.common.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.config.common.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.config.common.public,
            dependency.spryker_variables.outputs.discovered_ssm_params.config.pipeline.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.config.pipeline.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.config.pipeline.public
          ) : k => { value = v.value, type = "PLAINTEXT" } },
          { for k, v in merge(
            dependency.spryker_secrets_custom.outputs.ssm_parameter_address,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.public,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.public
          ) : k => { value = v.name, type = "PARAMETER_STORE" } if !can(regex(dependency.spryker_variables.outputs.regex_nonsensitive, v.value)) },
          { for k, v in merge(
            dependency.spryker_secrets_custom.outputs.ssm_parameter_address,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.common.public,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.internal,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.limited,
            dependency.spryker_variables.outputs.discovered_ssm_params.secret.pipeline.public
          ) : k => { value = v.value, type = "PLAINTEXT" } if can(regex(dependency.spryker_variables.outputs.regex_nonsensitive, v.value)) },
          { for k, v in dependency.ecr.outputs.repository_urls : "${upper(k)}_ECR_REPO" => { value = v, type = "PLAINTEXT" } },
          {
            PROJECT_NAME             = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.SPRYKER_PROJECT_NAME
            SPRYKER_PROJECT_NAME     = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.SPRYKER_PROJECT_NAME
            INIT_IMAGE_PREFIX        = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.INIT_IMAGE_PREFIX
            GRACEFUL_SHUTDOWN_PERIOD = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.GRACEFUL_SHUTDOWN_PERIOD
            JENKINS_IMAGE            = { value = "${dependency.ecr.outputs.repository_urls["jenkins"]}", type = "PLAINTEXT" }
            SFTP_EFS_MOUNT_POINT     = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.SFTP_EFS_MOUNT_POINT
            AWS_REGION               = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.AWS_REGION
            NEWRELIC_INTEGRATION     = local.codebuild-project.locals.codebuild_projects_config.scheduler.environment_config.environment_variables.NEWRELIC_INTEGRATION
            NRIA_LICENSE_KEY         = { value = "${dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_license_key"]}", type = "PLAINTEXT" }
            REGION                   = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.REGION
            SPRYKER_SDK_REPO         = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.SPRYKER_SDK_REPO
            SPRYKER_SDK_BRANCH       = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.SPRYKER_SDK_BRANCH
            JENKINS_ECR_REPO         = { value = "${dependency.ecr.outputs.repository_urls["jenkins"]}", type = "PLAINTEXT" }
            GITHUB_TOKEN             = { value = "${dependency.vault_secrets.outputs.spryker_secrets["github_token"]}", type = "PLAINTEXT" }
            DOCKERHUB_USERNAME       = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.DOCKERHUB_USERNAME
            DOCKERHUB_PASSWORD       = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.DOCKERHUB_PASSWORD
            ENVIRONMENT_ARCHITECTURE = local.codebuild-project.locals.codebuild_projects_config.app_build.environment_config.environment_variables.ENVIRONMENT_ARCHITECTURE
        })
      }
      vpc_config = {
        vpc_id              = dependency.vpc.outputs.vpc_id
        subnets_ids         = dependency.vpc.outputs.private_cmz_subnet_ids
        security_groups_ids = [dependency.security_group.outputs.security_group]
      }
      tags = {}
    }
  }

}
