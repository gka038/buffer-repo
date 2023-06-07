locals {
  enabled                  = false
  buddy_region             = "EU" # OPTIONS "US" or "EU"
  buddy_github_user        = "<template:change-me>"
  repository_path          = "<template:change-me>" # admin right for the repo is required!
  repository_branch_buddy  = "<template:change-me>"
  email_list               = []
  admin_list               = []
  auto_deploy              = false
  upgrader_exec_interval   = 7
  upgrader_auto_merge      = false
  spryker_static_apps      = "frontend jenkins"
  # Remote Templates
  spryker_pipelines_branch = "buddy"
  is_production            = false
  remote_pipelines_path    = "refactored/buddy/remote-pipelines"

  # 60-extra/buddy/buddy-paas related settings
  buddy-paas = {
    enable_paas                       = false
    customer_projects                 = ["default"]
    spryker_infra_validator_image     = "spryker/infra-validator"
    spryker_infra_validator_image_tag = "0.1-beta2"
    spryker_infra_generator_image     = "spryker/infra-generator"
    spryker_infra_generator_image_tag = "0.1-beta3"
  }
}
