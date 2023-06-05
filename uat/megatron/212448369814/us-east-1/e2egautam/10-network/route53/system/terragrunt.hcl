include {
  path = find_in_parent_folders()
}

generate "provider" {
  path              = "frontend.json"
  if_exists         = "overwrite"
  contents          = file("../../../frontend.json")
  disable_signature = true
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/route53_records?ref=23_01.0"
}

dependency "alb" {
  config_path = find_in_parent_folders("10-network/lb/external_alb")

  
  mock_outputs = {
    alb_fqdn    = "mock"
    alb_zone_id = "mock"
  }
}

dependency "nlb" {
  config_path = find_in_parent_folders("10-network/lb/internal_nlb")

  
  mock_outputs = {
    dns_name = "mock"
    zone_id  = "mock"
  }
}

dependency "bastion" {
  config_path = find_in_parent_folders("10-network/ec2/bastion")

  
  mock_outputs = {
    bastion_public_ip = "mock"
  }
}

dependency "zone" {
  config_path = find_in_parent_folders("00-initial-infra/route53/zone")

  
  mock_outputs = {
    zone_name = "mock"
  }
}

inputs = {
  route53_zone_domain        = dependency.zone.outputs.zone_name
  internal_balancer_dns_name = dependency.nlb.outputs.dns_name
  internal_balancer_zone_id  = dependency.nlb.outputs.zone_id
  bastion_public_ip          = dependency.bastion.outputs.bastion_public_ip
  external_balancer_fqdn     = dependency.alb.outputs.alb_fqdn
  external_balancer_zone_id  = dependency.alb.outputs.alb_zone_id
  scheduler_fqdn_ec2         = local.spryker.locals.scheduler_fqdn
}
