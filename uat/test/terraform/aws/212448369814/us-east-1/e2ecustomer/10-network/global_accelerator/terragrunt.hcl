include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  ga      = read_terragrunt_config(find_in_parent_folders("config/network/global-accelerator.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/global_accelerator?ref=23_02.0"
}

dependency "external_alb" {
  config_path = find_in_parent_folders("10-network/lb/external_alb")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    alb_arn = "arn:aws:iam::123456789012:mock"
  }
}

skip = !local.ga.locals.ga_enabled

inputs = {
  project_name                  = local.spryker.locals.project_name
  frontend_elb_arn              = dependency.external_alb.outputs.alb_arn
  ip_address_type               = local.ga.locals.ip_address_type
  listener_ports                = local.ga.locals.listener_ports
  health_check_interval_seconds = local.ga.locals.health_check_interval_seconds
  health_check_port             = local.ga.locals.health_check_port
  health_check_path             = local.ga.locals.health_check_path
}
