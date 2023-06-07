include {
  path = find_in_parent_folders()
}

locals {
  spryker           = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  codebuild-project = read_terragrunt_config(find_in_parent_folders("config/deployment/codebuild.hcl"))
  repoconf          = read_terragrunt_config(find_in_parent_folders("config/deployment/repoconf.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/aws_codebuild?ref=feature/SC-13182/change-s3-structure"
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

dependency "iam_role" {
  config_path = find_in_parent_folders("00-initial-infra/iam/codebuild")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    codebuild_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "s3" {
  config_path = find_in_parent_folders("00-initial-infra/s3/internal")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    codebuild_s3_bucket_name = "mock"
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

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  codebuild_projects_variables = {
    project_name = local.spryker.locals.project_name
  }
  codebuild_projects_config = {
    "e2e_tests" = {
      namebase             = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.namebase
      description          = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.description
      build_timeout        = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.build_timeout
      service_role_arn     = dependency.iam_role.outputs.codebuild_role_arn
      artifacts            = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.artifacts
      secondary_artifact   = null
      cache_config         = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.cache_config
      source_template      = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.source_template
      source_template_vars = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.source_template_vars
      source_type          = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.source_type
      environment_config = {
        compute_type                = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.environment_config.compute_type
        image                       = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.environment_config.image
        image_pull_credentials_type = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.environment_config.image_pull_credentials_type
        type                        = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.environment_config.type
        privileged_mode             = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.environment_config.privileged_mode
        registry_credential         = local.codebuild-project.locals.codebuild_projects_config.e2e_tests.environment_config.registry_credential
        environment_variables = merge ( { for k, v in dependency.spryker_variables.outputs.environment_variables["e2e"] : k => { value = v, type = "PLAINTEXT" } },
          {
          S3_E2E_PATH  = { value = "${dependency.s3.outputs.internal_s3_bucket_name}/e2e", type = "PLAINTEXT" }
          GITHUB_TOKEN = { value = "${dependency.vault_secrets.outputs.spryker_secrets["github_token"]}", type = "PLAINTEXT" }
          SPRYKER_E2E_PROJECT_NAME  = { value = local.repoconf.locals.repotype, type = "PLAINTEXT" }
          SCHEDULER_URL = { value = local.spryker.locals.scheduler_fqdn , type = "PLAINTEXT" }
          RABBITMQ_URL =  { value = "rabbitmq.${local.spryker.locals.route53_zone_domain}", type = "PLAINTEXT" }
        } )
      }
      secondary_sources = null
      vpc_config = {
        vpc_id              = dependency.vpc.outputs.vpc_id
        subnets_ids         = dependency.vpc.outputs.private_cmz_subnet_ids
        security_groups_ids = [dependency.security_group.outputs.security_group]
      }
      tags              = {}
    }
  }
}
