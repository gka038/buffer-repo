locals {
  spryker = read_terragrunt_config("${get_parent_terragrunt_dir()}/config/common/spryker.hcl")
  buddy   = read_terragrunt_config("${get_parent_terragrunt_dir()}/config/buddy/buddy.hcl")
  # following map is used to override default provider version constraints
  # for the purposes of the migration process (limiting bastion and jenkins downtime), following must be set: 
  provider_version_overrides = {}
}

dependency "vault_secrets" {
  config_path = "${get_parent_terragrunt_dir()}/vault-secrets"
}

remote_state {
  backend = "s3"
  config = {
    disable_bucket_update = true                # needs to be commented when using terragrunt < v0.37.0
    region                = "eu-central-1"      # this region cannot be changed, it's only for the spryker-tf-states bucket
    bucket                = "spryker-tf-states" # we keep all states in one bucket
    dynamodb_table        = "spryker-tf-lock"
    key                   = "${local.spryker.locals.customer_name}/${local.spryker.locals.customer_project}/project/${path_relative_to_include()}/terraform.tfstate"
  }
}

inputs = {
  region = local.spryker.locals.region
}

terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
    # You can uncomment it on local machine if needed, but keep in mind the concurrency of different version for different envs
    #env_vars = {
    #  TF_PLUGIN_CACHE_DIR = "${get_env("HOME")}/.tf_plugins_cache",
    #}

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

EOF
}

generate "providers" {
  path              = "providers.tf"
  if_exists         = "overwrite"
  disable_signature = true
  contents = templatefile("providers.tftpl", {

    provider_version_constraints = {
      buddy = lookup(lookup(local.provider_version_overrides, path_relative_to_include(), {}), "buddy", ">= 1.4.1")
    }

    provider_parameters = {
      buddy_personal_token = dependency.vault_secrets.outputs.spryker_secrets["buddy_personal_token"]
      buddy_region         = local.buddy.locals.common.buddy_region
    }
  })
}
