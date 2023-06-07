locals {
  #00-initial-infra/02-iam/02-service-linked-roles
  slr = {
    enable_es_role  = false
    enable_ssm_role = false
    elasticsearch_role_name = "AWSServiceRoleForAmazonElasticsearchService"
  }
  ssm = {
    apply_rollback = false
  }
  customer = {
    additional_policy_arns = []
  }
}
