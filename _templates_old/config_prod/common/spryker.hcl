locals {
  secrets                   = read_terragrunt_config(find_in_parent_folders("secrets/common/spryker.hcl"))
  newrelic                  = read_terragrunt_config(find_in_parent_folders("config/monitoring/newrelic.hcl"))
  spryker_ecs_services      = ["frontend", "yves", "glue", "boffice", "backapi", "backgw", "rabbitmq", "blackfire", "mportal", "jenkins"] // full list of enabled ecs services
  spryker_nonecs_services   = []
  spryker_services          = local.newrelic.locals.newrelic_integration.enable_production_mode ? concat(local.spryker_ecs_services, local.monitoring_services, local.spryker_nonecs_services) : concat(local.spryker_ecs_services, local.spryker_nonecs_services)
  services_to_restart       = ["frontend", "yves", "glue", "boffice", "backapi", "backgw"]
  spryker_ecr_repos         = ["frontend", "yves", "glue", "boffice", "backapi", "backgw", "rabbitmq", "blackfire", "jenkins", "mportal", "pipeline"] # pipeline repository is obligatory starting from 6.0, docker/sdk produces image inside of it
  region                    = "eu-central-1"
  project_owner             = "<template:customer>"
  project_name              = "<template:customer-env>"
  env_type                  = "<template:env>"
  route53_zone_domain       = "<template:customer-env>.cloud.spryker.systems"
  scheduler_fqdn            = "jenkins.<template:customer-env>.cloud.spryker.systems"
  scheduler_type            = "ecs" # For ec2, add jenkins value into spryker_nonecs_services and remove from spryker_ecs_services
  spryker_ssl_enable        = "1"
  health_check_enabled      = "1"
  tideways_enabled          = false
  tideways_api_key          = local.secrets.locals.tideways_api_key
  spryker_api_port          = 80
  spryker_be_port           = 80
  spryker_fe_port           = 80
  spryker_zed_port          = 80
  spryker_scheduler_port    = 80
  jenkins_template_path     = "/data/config/Zed/cronjobs/jenkins.docker.xml.twig"
  elasticsearch_port        = 80
  default_credentials_token = local.secrets.locals.default_credentials_token
  payone_credentials        = local.secrets.locals.payone_credentials
  broker_api_user           = local.secrets.locals.broker_api_user
  broker_api_user_password  = local.secrets.locals.broker_api_user_password
  broker_user               = local.secrets.locals.broker_user
  broker_user_password      = local.secrets.locals.broker_user_password
  broker_protocol           = "TCP" // can be TLS
  broker_api_port           = "15672"
  broker_port               = "5672"
  smtp_auth_mode            = "plain"
  smtp_encryption           = "tls"
  smtp_port                 = 587
  jenkins_java_opts         = "-Djenkins.install.runSetupWizard=false -Dhudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION=true"
  blackfire_server_id       = local.secrets.locals.blackfire_server_id
  blackfire_server_token    = local.secrets.locals.blackfire_server_token
  rabbitmq_nodename         = "rabbitmq@localhost"
  rabbitmq_default_user     = local.secrets.locals.rabbitmq_default_user
  rabbitmq_default_pass     = local.secrets.locals.rabbitmq_default_pass
  rabbitmq_default_vhost    = "/"
  oneagent_script_url       = local.secrets.locals.oneagent_script_url
  oneagent_download_token   = local.secrets.locals.oneagent_download_token
  monitoring_services       = ["newrelic-host-agent", "newrelic-rabbitmq-monitoring", "newrelic-jenkins-host-agent"] // this is constant value used in spryker_services when newrelic enable_producation_mode set to true
  deploy_file               = "deploy.<template:customer-env>.yml"
  aop_authentication        = local.secrets.locals.aop_authentication
  aws_account_environment   = "<template:env>" // only use "production" or "non-production" for customers and "internal" for sandboxes
  released_version          = "<template:released_version>" //git tagged version. ie. 7.0.0
  tags = {
    environment = local.env_type
    project     = local.project_owner
  }
}
