locals {
  settings = {
    "instance_size"              = "cache.t3.medium" # previously t2.medium, BTW, are we really need medium (3 Gb) Redis on stage envs? We can use small (1.37 Gb)
    "port"                       = 6379
    "number_cache_clusters"      = 2       # must be at least 2 if multi_az_enabled = TRUE
    "engine_version"             = "6.2"
    "parameter_group_family"     = "redis6.x"
    "multi_az_enabled"           = true # When set to TRUE, make Terraform Apply, then set "automatic_failover_enabled" to TRUE and make Terraform Apply again
    "automatic_failover_enabled" = true # Must be set to FALSE if updating 1 node cluster and set to TRUE if multi_az_enabled is set to TRUE
    "database_limit"             = 1024
    "snapshot_retention_limit"   = "7"
    "encryption_at_rest"         = true
    "encryption_in_transit"      = false
    "apply_immediately"          = true
  }
}
