locals {
  # 00-initial-infra/01-kms/01-rds/terragrunt.hcl
  rds = {
    key_description = "RDS encryption key"
  }
  # 00-initial-infra/01-kms/02-elasticache
  elasticache = {
    key_description = "Redis encryption key"
  }
  # 00-initial-infra/01-kms/02-elasticache
  search = {
    key_description = "ElasticSearch/Opensearch encryption key"
  }
  
}
