locals {
  spryker       = read_terragrunt_config("${get_parent_terragrunt_dir()}/config/common/spryker.hcl")
  # following map is used to override default provider version constraints
  # for the purposes of the migration process (limiting bastion and jenkins downtime), following must be set: 
  provider_version_overrides = {}
}

remote_state {
  backend = "s3"
  config = {
    disable_bucket_update = true                # needs to be commented when using terragrunt < v0.37.0
    region                = "eu-central-1"      # this region cannot be changed, it's only for the spryker-tf-states bucket
    bucket                = "spryker-tf-states" # Do NOT change bucket name: we keep all states in one bucket under Spryker Cloud Platform Shared AWS account
    dynamodb_table        = "spryker-tf-lock"
    key                   = "${local.spryker.locals.customer_name}/${local.spryker.locals.customer_project}/${local.spryker.locals.aws_account_id}/account/${path_relative_to_include()}/terraform.tfstate"
  }
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
      aws      = lookup(lookup(local.provider_version_overrides, path_relative_to_include(), {}), "aws", "~> 4.64")
      vault    = lookup(lookup(local.provider_version_overrides, path_relative_to_include(), {}), "vault", ">= 3.0.1")
    }

    provider_parameters = {
      aws_region               = local.spryker.locals.region
      aws_account_id           = local.spryker.locals.aws_account_id
      customer_name            = local.spryker.locals.customer_name
      customer_project         = local.spryker.locals.customer_project
      release_version          = local.spryker.locals.release_version
    }
  })
}
