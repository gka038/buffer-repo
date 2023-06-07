locals {
  common = {
    buddy_enabled = false
    buddy_region  = "EU" # OPTIONS "US" or "EU"
  }
  workspace = {
    spryker_admin_emails     = ["<template:spryker_admins>"]
    customer_admin_emails    = ["<template:customer_admins>"]
    spryker_pipelines_branch = "development"
    projects_list            = ["upgrader"] //"pipelines", "paas_configuration" or []
    upgrader_delay           = 10080        //How many minutes between upgrader runs
    newrelic_appname         = "Spryker Code Upgrader"
    app_env                  = "sprykerci"
    newrelic_enabled         = true
  }
  customer_paas = {
    cda_buffer_repo                   = "spryker-projects/infra-configuration-dev"
    cda_buffer_repo_branch            = "main"
    repository_path                   = "spryker-projects/ops-config-dev" # boilerplate repo
    spryker_infra_validator_image     = "spryker/infra-validator"
    spryker_infra_validator_image_tag = "0.1-beta6"
    spryker_infra_generator_image     = "spryker/infra-generator"
    spryker_infra_generator_image_tag = "0.1-beta7"
    remote_pipelines_project_branch   = "feat/buddy-ops-dev"
    remote_pipelines_project_path     = "/refactored/buddy/remote-pipelines/buddy_customer_paas"
  }
}
