locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

remote_state {
  backend = "s3"
  config = {
    disable_bucket_update = true                # needs to be commented when using terragrunt < v0.37.0
    region                = "eu-central-1"      # this region cannot be changed, it's only for the spryker-tf-states bucket
    bucket                = "spryker-tf-states" # Do NOT change bucket name: we keep all states in one bucket under Spryker Cloud Platform Shared AWS account
    dynamodb_table        = "spryker-tf-lock"
    key                   = "${local.spryker.locals.customer_name}/${local.spryker.locals.customer_project}/project/vault-secrets/terraform.tfstate"
  }
}

generate "backend" {
  path              = "backend.tf"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<EOF

terraform {
  backend "s3" {}
}

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }
  }
}

provider "vault" {
  address = "https://vault.spryker.systems:8200"
}
EOF
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/vault_secrets?ref=feat/move-buddy-workspace"
}

inputs = {
  project_owner    = local.spryker.locals.customer_name
  project_env      = "non-existent"
  customer_project = local.spryker.locals.customer_project
  project_only     = true
}
