include {
  path = find_in_parent_folders()
}

locals {
  spryker = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
}

terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/iam/csv_uploads?ref=23_02.0"
}

dependency "s3_csv_uploads" {
  config_path = find_in_parent_folders("00-initial-infra/s3/csv-uploads")

  mock_outputs_allowed_terraform_commands = ["plan"]
  mock_outputs = {
    csv_bucket_arn = "arn:aws:iam::123456789012:mock"
  }
}

inputs = {
  project_name   = local.spryker.locals.project_name
  csv_bucket_arn = dependency.s3_csv_uploads.outputs.csv_bucket_arn
}
