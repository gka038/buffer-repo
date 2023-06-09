locals {
  enabled                                   = false
  device_name                               = null
  description                               = null
  site2site_customer_gateway_ip_address     = "<template:change-me>"
  site2site_customer_gateway_bgp_asn        = 65000
  site2site_routes                          = []
  site2site_static_routs_only               = true
  site2site_transit_gateway_amazon_side_asn = 64512
  tunnel_ike_versions                       = null
  tunnel_phase_dh_group_numbers             = null
  tunnel_phase_encryption_algorithms        = null
  tunnel_phase_integrity_algorithms         = null
  tunnel_rekey_margin_time_seconds          = 540
  tunnel_phase1_lifetime_seconds            = 28800
  tunnel_phase2_lifetime_seconds            = 3600
  tunnel_startup_action                     = "add"
  transit_gateway_id                        = ""
  transit_gateway_attachment_id             = ""
  name                                      = ""
}
