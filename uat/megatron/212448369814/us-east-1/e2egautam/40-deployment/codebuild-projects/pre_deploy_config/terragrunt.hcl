include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codebuild-project = read_terragrunt_config(find_in_parent_folders("config/deployment/codebuild.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_codebuild?ref=23_01.0"
}

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codebuild")

  
  mock_outputs = {
    codebuild_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "dockerhub_creds" {
  config_path  = find_in_parent_folders("00-initial-infra/secrets-manager/dockerhub-creds")
  skip_outputs = true
}

dependency "s3_codebuild" {
  config_path = find_in_parent_folders("00-initial-infra/s3/conf.d")

  
  mock_outputs = {
    codebuild_s3_bucket_name = "mock"
  }
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  
  mock_outputs = {
    vpc_id                 = "mock"
    private_cmz_subnet_ids = ["mock"]
  }
}

dependency "ecr" {
  config_path = find_in_parent_folders("20-aws-based-infra/ecr")

  
  mock_outputs = {
    repository_urls = { boffice = "mock", jenkins = "mock" }
  }
}

dependency "security_group" {
  config_path = find_in_parent_folders("10-network/security_groups/codebuild")

  
  mock_outputs = {
    security_group = "mock"
  }
}

dependency "spryker_variables" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-variables")

  
  mock_outputs = {
    environment_variables = { boffice = {}, jenkins = {} }
    discovered_ssm_params = {
      secret = { common = { internal = {}, limited = {}, public = {} }, app = { internal = {}, limited = {}, public = {} }, scheduler = { internal = {}, limited = {}, public = {} }, pipeline = { internal = {}, limited = {}, public = {} } }
      config = { common = { internal = {}, limited = {}, public = {} }, app = { internal = {}, limited = {}, public = {} }, scheduler = { internal = {}, limited = {}, public = {} }, pipeline = { internal = {}, limited = {}, public = {} } }
    }
  }
}

dependency "spryker_secrets_custom" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-secrets/custom-secrets")

  
  mock_outputs = {
    ssm_parameter_address = {}
  }
}

dependency "spryker_secrets_base" {
  config_path = find_in_parent_folders("30-spryker-services/spryker-environment/spryker-secrets/base-task-definition")

  
  mock_outputs = {
    ssm_parameter_address = {}
  }
}

inputs = {
  codebuild_projects_variables = {
    project_name = local.spryker.locals.project_name
  }
  codebuild_projects_config = {
    "pre_deploy_config" = {
      namebase             = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.namebase
      description          = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.description
      build_timeout        = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.build_timeout
      service_role_arn     = dependency.iam_role.outputs.codebuild_role_arn
      artifacts            = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.artifacts
      secondary_artifact   = null
      cache_config         = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.cache_config
      source_template      = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.source_template
      source_template_vars = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.source_template_vars
      source_type          = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.source_type
      environment_config = {
        compute_type                = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.environment_config.compute_type
        image                       = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.environment_config.image
        image_pull_credentials_type = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.environment_config.image_pull_credentials_type
        type                        = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.environment_config.type
        privileged_mode             = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.environment_config.privileged_mode
        registry_credential         = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.environment_config.registry_credential
        environment_variables = merge(
          { for k, v in try(dependency.spryker_variables.outputs.environment_variables["boffice"], dependency.spryker_variables.outputs.environment_variables["zed"]) : k => { value = v, type = "PLAINTEXT" } },
          { for k, v in dependency.spryker_secrets_base.outputs.ssm_parameter_address : k => { value = v.name, type = "PARAMETER_STORE" } if can(regex(dependency.spryker_variables.outputs.regex_sensitive, k)) && !can(regex(dependency.spryker_variables.outputs.regex_nonsensitive, v.value)) },
          { for k, v in dependency.spryker_secrets_base.outputs.ssm_parameter_address : k => { value = v.value, type = "PLAINTEXT" } if !can(regex(dependency.spryker_variables.outputs.regex_sensitive, k)) || can(regex(dependency.spryker_variables.outputs.regex_nonsensitive, v.value)) },
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
        )
      }
      vpc_config = {
        vpc_id              = dependency.vpc.outputs.vpc_id
        subnets_ids         = dependency.vpc.outputs.private_cmz_subnet_ids
        security_groups_ids = [dependency.security_group.outputs.security_group]
      }
      secondary_sources = {
        type              = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.secondary_sources.type
        source_identifier = local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.secondary_sources.source_identifier
        location          = "${dependency.s3_codebuild.outputs.codebuild_s3_bucket_name}${local.codebuild-project.locals.codebuild_projects_config.pre_deploy_config.secondary_sources.location_suffix}"
      }
      tags = {}
    }
  }
}
