include {
  path = find_in_parent_folders()
}

locals {
  spryker                = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  newrelic               = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic.hcl"))
  sdk_vars               = read_terragrunt_config(find_in_parent_folders("environment.tf"))
  nria_custom_atrributes = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic_custom_attributes.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/spryker_variables?ref=development"
}

dependency "iam_ses" {
  config_path = find_in_parent_folders("00-initial-infra/iam/ses")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    smtp_user = "mock"
    smtp_pass = "mock"
  }
}

dependency "iam_csv_uploads" {
  config_path = find_in_parent_folders("00-initial-infra/iam/csv-uploads")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    csv_bucket_access_id     = "mock"
    csv_bucket_access_secret = "mock"
  }
}

dependency "s3_csv_uploads" {
  config_path = find_in_parent_folders("00-initial-infra/s3/csv-uploads")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    csv_bucket_name = "mock"
  }
}

dependency "vpc" {
  config_path = find_in_parent_folders("10-network/vpc")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    nat_redundancy = false
    nat_public_ip  = ["mock"]
    vpc_cidr_block = "10.0.0.0/24"
  }
}

dependency "internal_nlb" {
  config_path = find_in_parent_folders("10-network/lb/internal_nlb")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    dns_name = "mock"
  }
}

dependency "rds" {
  config_path = find_in_parent_folders("20-aws-based-infra/rds")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    db_password = "mock"
    endpoint    = "mock"
    port        = "mock"
    username    = "mock"
  }
}

dependency "search" {
  config_path = find_in_parent_folders("20-aws-based-infra/search")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    endpoint = "mock"
  }
}

dependency "elasticache" {
  config_path = find_in_parent_folders("20-aws-based-infra/elasticache")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    endpoint = "mock"
    port     = "mock"
  }
}

dependency "vault_secrets" {
  config_path = find_in_parent_folders("00-initial-infra/vault-secrets")
}


inputs = {
  project_owner    = local.spryker.locals.project_owner
  env_type         = local.spryker.locals.env_type
  spryker_services = concat(local.spryker.locals.spryker_services,["e2e"])
  # variables from environment.tf
  spryker_variables_sdk = local.sdk_vars.locals.spryker_environment

  spryker_variables = {
    "AWS_REGION"                             = local.spryker.locals.region
    "SPRYKER_PROJECT_OWNER"                  = local.spryker.locals.project_owner
    "SPRYKER_PROJECT_ENV"                    = local.spryker.locals.env_type
    "SPRYKER_PROJECT_NAME"                   = local.spryker.locals.project_name
    "BLACKFIRE_AGENT_SOCKET"                 = "tcp://${dependency.internal_nlb.outputs.dns_name}:8707"
    "NEWRELIC_APPNAME"                       = "${local.spryker.locals.project_name}-newrelic-app"
    "NEWRELIC_ENABLED"                       = local.newrelic.locals.newrelic_integration.enable_integration
    "NEWRELIC_LICENSE"                       = dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_apm_license_key"]
    "SPRYKER_NEWRELIC_ACCOUNT_ID"            = dependency.vault_secrets.outputs.spryker_secrets["newrelic_metrics_account_id"]
    "SPRYKER_NEWRELIC_INSIGHTS_KEY"          = dependency.vault_secrets.outputs.spryker_secrets["newrelic_metrics_ingest_key"]
    "TIDEWAYS_CLI_ENABLED"                   = local.spryker.locals.tideways_enabled
    "TIDEWAYS_APIKEY"                        = dependency.vault_secrets.outputs.spryker_secrets["tideways_api_key"]
    "SPRYKER_API_PORT"                       = local.spryker.locals.spryker_api_port
    "SPRYKER_BE_PORT"                        = local.spryker.locals.spryker_be_port
    "SPRYKER_FE_PORT"                        = local.spryker.locals.spryker_fe_port
    "SPRYKER_ZED_PORT"                       = local.spryker.locals.spryker_zed_port
    "SPRYKER_JENKINS_TEMPLATE_PATH"          = local.spryker.locals.jenkins_template_path
    "SPRYKER_KEY_VALUE_STORE_HOST"           = dependency.elasticache.outputs.endpoint
    "SPRYKER_KEY_VALUE_STORE_PORT"           = dependency.elasticache.outputs.port
    "SPRYKER_SCHEDULER_HOST"                 = local.spryker.locals.scheduler_fqdn
    "SPRYKER_SCHEDULER_PORT"                 = local.spryker.locals.spryker_scheduler_port
    "SPRYKER_SEARCH_HOST"                    = dependency.search.outputs.endpoint
    "SPRYKER_SEARCH_PORT"                    = local.spryker.locals.elasticsearch_port
    "SPRYKER_SESSION_BE_HOST"                = dependency.elasticache.outputs.endpoint
    "SPRYKER_SESSION_BE_PORT"                = dependency.elasticache.outputs.port
    "SPRYKER_SESSION_FE_HOST"                = dependency.elasticache.outputs.endpoint
    "SPRYKER_SESSION_FE_PORT"                = dependency.elasticache.outputs.port
    "SPRYKER_SMTP_AUTH_MODE"                 = local.spryker.locals.smtp_auth_mode
    "SPRYKER_SMTP_ENCRYPTION"                = local.spryker.locals.smtp_encryption
    "SPRYKER_SMTP_HOST"                      = "email-smtp.${local.spryker.locals.region}.amazonaws.com"
    "SPRYKER_SMTP_USERNAME"                  = dependency.iam_ses.outputs.smtp_user
    "SPRYKER_SMTP_PASSWORD"                  = dependency.iam_ses.outputs.smtp_pass
    "SPRYKER_SMTP_PORT"                      = local.spryker.locals.smtp_port
    "SPRYKER_AUTH_DEFAULT_CREDENTIALS_TOKEN" = dependency.vault_secrets.outputs.spryker_secrets["default_credentials_token"]
    "SPRYKER_PAYONE_CREDENTIALS"             = dependency.vault_secrets.outputs.spryker_secrets["payone_credentials"]
    "SPRYKER_MAIL_SENDER_NAME"               = "${local.spryker.locals.project_name}-No-Reply"
    "SPRYKER_MAIL_SENDER_EMAIL"              = "no-reply@${local.spryker.locals.route53_zone_domain}"
    "SPRYKER_SSL_ENABLE"                     = local.spryker.locals.spryker_ssl_enable
    "SPRYKER_BROKER_PROTOCOL"                = local.spryker.locals.broker_protocol
    "SPRYKER_BROKER_API_HOST"                = "rabbitmq.${local.spryker.locals.route53_zone_domain}"
    "SPRYKER_BROKER_API_PORT"                = local.spryker.locals.broker_api_port
    "SPRYKER_BROKER_API_USERNAME"            = local.spryker.locals.broker_api_user
    "SPRYKER_BROKER_API_PASSWORD"            = dependency.vault_secrets.outputs.spryker_secrets["broker_api_user_password"]
    "SPRYKER_BROKER_HOST"                    = "rabbitmq.${local.spryker.locals.route53_zone_domain}"
    "SPRYKER_BROKER_PORT"                    = local.spryker.locals.broker_port
    "SPRYKER_BROKER_USERNAME"                = local.spryker.locals.broker_user
    "SPRYKER_BROKER_PASSWORD"                = dependency.vault_secrets.outputs.spryker_secrets["broker_user_password"]
    "SPRYKER_DB_HOST"                        = dependency.rds.outputs.endpoint
    "SPRYKER_DB_PASSWORD"                    = dependency.rds.outputs.db_password
    "SPRYKER_DB_PORT"                        = dependency.rds.outputs.port
    "SPRYKER_DB_ROOT_PASSWORD"               = dependency.rds.outputs.db_password
    "SPRYKER_DB_ROOT_USERNAME"               = dependency.rds.outputs.username
    "SPRYKER_DB_USERNAME"                    = dependency.rds.outputs.username
    "SPRYKER_DB_IDENTIFIER"                  = local.spryker.locals.project_name
    "DATA_IMPORT_S3_BUCKET"                  = dependency.s3_csv_uploads.outputs.csv_bucket_name
    "DATA_IMPORT_S3_KEY"                     = dependency.iam_csv_uploads.outputs.csv_bucket_access_id
    "DATA_IMPORT_S3_SECRET"                  = dependency.iam_csv_uploads.outputs.csv_bucket_access_secret
    "SPRYKER_HEALTH_CHECK_ENABLED"           = local.spryker.locals.health_check_enabled
    "SPRYKER_NGINX_CGI_YVES"                 = "${dependency.internal_nlb.outputs.dns_name}:9001"
    "SPRYKER_NGINX_CGI_ZED"                  = "${dependency.internal_nlb.outputs.dns_name}:9002"
    "SPRYKER_NGINX_CGI_GLUE"                 = "${dependency.internal_nlb.outputs.dns_name}:9003"
    "SPRYKER_NGINX_CGI_MPORTAL"              = "${dependency.internal_nlb.outputs.dns_name}:9004"
    "SPRYKER_NGINX_CGI_BOFFICE"              = "${dependency.internal_nlb.outputs.dns_name}:9005"
    "SPRYKER_NGINX_CGI_BACKAPI"              = "${dependency.internal_nlb.outputs.dns_name}:9006"
    "SPRYKER_NGINX_CGI_BACKGW"               = "${dependency.internal_nlb.outputs.dns_name}:9007"
    "SPRYKER_NGINX_CGI_GLUESTOREFRONT"       = "${dependency.internal_nlb.outputs.dns_name}:9010"
    "SPRYKER_NGINX_CGI_GLUEBACKEND"          = "${dependency.internal_nlb.outputs.dns_name}:9011"
    "ALLOWED_IP"                             = dependency.vpc.outputs.nat_redundancy ? "${dependency.vpc.outputs.nat_public_ip[0]}/32; allow ${dependency.vpc.outputs.nat_public_ip[1]}/32" : "${dependency.vpc.outputs.nat_public_ip[0]}/32"
    "SPRYKER_DNS_RESOLVER_IP"                = cidrhost(dependency.vpc.outputs.vpc_cidr_block, 2)
    "JAVA_OPTS"                              = local.spryker.locals.jenkins_java_opts
    "JENKINS_URL"                            = "http://jenkins.${local.spryker.locals.route53_zone_domain}"
    "BLACKFIRE_SERVER_ID"                    = dependency.vault_secrets.outputs.spryker_secrets["blackfire_server_id"]
    "BLACKFIRE_SERVER_TOKEN"                 = dependency.vault_secrets.outputs.spryker_secrets["blackfire_server_token"]
    "RABBITMQ_DEFAULT_PASS"                  = dependency.vault_secrets.outputs.spryker_secrets["rabbitmq_default_pass"]
    "RABBITMQ_DEFAULT_USER"                  = local.spryker.locals.rabbitmq_default_user
    "RABBITMQ_DEFAULT_VHOST"                 = local.spryker.locals.rabbitmq_default_vhost
    "RABBITMQ_NODENAME"                      = local.spryker.locals.rabbitmq_nodename
    "ONEAGENT_INSTALLER_SCRIPT_URL"          = local.spryker.locals.oneagent_script_url
    "ONEAGENT_INSTALLER_DOWNLOAD_TOKEN"      = dependency.vault_secrets.outputs.spryker_secrets["oneagent_download_token"]
    "ENABLE_NRI_ECS"                         = local.newrelic.locals.enable_nri_ecs
    "NRIA_OVERRIDE_HOST_ROOT"                = local.newrelic.locals.nria_override_host_root
    "NRIA_PASSTHROUGH_ENVIRONMENT"           = local.newrelic.locals.nria_passthrough_environment
    "NRIA_VERBOSE"                           = local.newrelic.locals.nria_verbose
    "NRIA_LICENSE_KEY"                       = dependency.vault_secrets.outputs.spryker_secrets["newrelic_integration_license_key"]
    "NRIA_CUSTOM_ATTRIBUTES"                 = jsonencode(local.nria_custom_atrributes.locals.nria_custom_atrributes)
    "RABBITMQ_ENDPOINT"                      = "rabbitmq.${local.spryker.locals.route53_zone_domain}"
    "RABBITMQ_PORT"                          = local.spryker.locals.broker_api_port
    "RABBITMQ_USERNAME"                      = local.spryker.locals.broker_api_user
    "RABBITMQ_PASSWORD"                      = dependency.vault_secrets.outputs.spryker_secrets["broker_api_user_password"]
    "RABBITMQ_USE_SSL"                       = local.spryker.locals.broker_protocol == "TCP" ? "false" : "true"
    "RABBITMQ_QUEUES_REGEXES"                = local.newrelic.locals.rabbitmq_queues_regexes
    "RABBITMQ_EXCHANGE_REGEXES"              = local.newrelic.locals.rabbitmq_exchange_regexes
    "RABBITMQ_INTEGRATIONS_INTERVAL"         = local.newrelic.locals.rabbitmq_integrations_interval
  }
}
