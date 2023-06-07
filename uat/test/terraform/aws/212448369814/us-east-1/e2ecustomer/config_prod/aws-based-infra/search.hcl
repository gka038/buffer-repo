locals {
  settings = {
    service               = "opensearch" # "opensearch" or "elasticsearch"
    storage_size          = 35
    volume_type           = "gp3"              # EBS volume type, gp2 or gp3
    encrypt               = false              # Enable encryption at rest for ElasticSearch (only specific instance family types support it: m4, c4, r4, i2, i3 default: false)
    version               = "OpenSearch_1.3"   # Maintainable versions: "7.7", "7.10" for ES and "OpenSearch_1.2", "OpenSearch_1.3" for OpenSearch. Elasticsearch versions without prefix, OpenSearch versions must be prefixed with "OpenSearch_".
    instance_size         = "t3.medium.elasticsearch" # Keep *.elasticsearch as is for both ElasticSearch and OpenSearch
    dedicated_master_type = "t3.medium.elasticsearch" # Keep *.elasticsearch as is for both ElasticSearch and OpenSearch
    port                  = 80
    logs_expire           = 60
    production_mode       = true
    data_nodes_count      = 2
    master_nodes_count    = 3
    advanced_security_options = {
      enabled = false
    }
  }
}
