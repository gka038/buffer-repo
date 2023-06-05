locals {
  ga_enabled                    = false
  ip_address_type               = "IPV4"
  listener_ports                = [80, 443]
  health_check_interval_seconds = 30
  health_check_port             = 80
  health_check_path             = "/"
}
