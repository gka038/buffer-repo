locals {
  # following API keys can be used for testing
  newrelic_integration = {
    license_key              = "<template:change_me>"
    newrelic_apm_license_key = "<template:change_me>"
    insights_key             = "<template:change_me>" //NRII
    api_key                  = "<template:change_me>" //NRAK
    account_id               = "1234567"
    opsgenie_api_key         = "<template:change_me>"
  }

  # NewRelic customer's dedicated account
  newrelic_customer_account = {
    account_id  = "<template:change_me>"
    license_key = "<template:change_me>" // NRAL
  }

  aws_integration = {
    role_name               = "Newrelic-Integrations"
    read_only_policy_arn    = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    newrelic_aws_account_id = 754728514883
  }

  basic_auth = {
    user     = "<template:change_me>"
    password = "<template:change_me>"
  }

  #SC-11152 - needed for NR matrix dashboard
  newrelic_metrics_account_id = "<template:change_me>"
  newrelic_metrics_ingest_key = "<template:change_me>"
}
