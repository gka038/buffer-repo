locals {
  region           = "<template:region>"
  customer_name    = "<template:customer-name>"
  customer_project = "<template:customer-project>"
  aws_account_id   = "066672170623" # used only for assume role purpose, hardcoded to Spryker Cloud Platform Shared (for now the only plan to use project template is to run buddy related pipelines)
  release_version  = "<template:release_version>"
}
