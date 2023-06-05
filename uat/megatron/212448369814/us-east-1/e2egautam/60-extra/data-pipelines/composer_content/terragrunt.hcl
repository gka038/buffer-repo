

include {
  path = find_in_parent_folders()
}

locals {
  spryker          = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  gmv_cc_shared    = read_terragrunt_config(find_in_parent_folders("config/extras/gmv_and_composer_shared.hcl"))
  composer_content = read_terragrunt_config(find_in_parent_folders("config/extras/composer_content.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/lambda/composer_content?ref=23_01.0"
}

skip = !local.gmv_cc_shared.locals.gmv_enabled

dependency "composer_content_secrets" {
  config_path = find_in_parent_folders("60-extra/data-pipelines/aws_secrets_manager")

  
  mock_outputs = {
    secret_arn = "arn:aws:iam::123456789012:mock"
  }
}

dependency "docker_build" {
  config_path = find_in_parent_folders("60-extra/data-pipelines/docker_build_composer_content")

  
  mock_outputs = {
    docker_image_uri = "mock"
  }
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  
  mock_outputs = {
    vpc_id                 = "mock"
    private_cmz_subnet_ids = ["mock"]
  }
}

dependency "vpc_security_group" {
  config_path = find_in_parent_folders("10-network/security_groups/initial")

  
  mock_outputs = {
    security_group = "mock"
  }
}

dependency "data_source" {
  config_path = find_in_parent_folders("00-initial-infra/s3/conf.d")

  
  mock_outputs = {
    codebuild_s3_bucket_name = "mock"
  }
}

dependency "aws_data" {
  config_path = find_in_parent_folders("00-initial-infra/aws-data")

  
  mock_outputs = {
    account_id = 123456789012
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}

inputs = {
  lambda_name                                      = "${local.spryker.locals.project_name}-composer-content"
  forward_rule_schedule_expression                 = local.composer_content.locals.forward_rule_schedule_expression
  lambda_secrets_region                            = local.spryker.locals.region
  lambda_security_group_ids                        = tolist([dependency.vpc_security_group.outputs.security_group])
  lambda_spryker_aws_account_email                 = local.gmv_cc_shared.locals.aws_environment_email
  lambda_spryker_aws_account_id                    = dependency.aws_data.outputs.account_id
  lambda_spryker_bucket_details_arn                = dependency.composer_content_secrets.outputs.secret_arn
  lambda_spryker_enabled_features_endpoint         = dependency.vault_secrets.outputs.spryker_secrets["lambda_spryker_enabled_features_endpoint"]
  lambda_spryker_enabled_features_endpoint_api_key = dependency.vault_secrets.outputs.spryker_secrets["lambda_spryker_enabled_features_endpoint_api_key"]
  lambda_subnet_ids                                = dependency.vpc.outputs.private_cmz_subnet_ids
  docker_image_uri                                 = dependency.docker_build.outputs.docker_image_uri
  create_retro_rule                                = local.composer_content.locals.create_retro_rule
  lambda_timeout                                   = local.composer_content.locals.lambda_timeout
  lambda_spryker_source_bucket_name                = dependency.data_source.outputs.codebuild_s3_bucket_name
  project_name                                     = local.spryker.locals.project_name
}
