locals {
  service_name                       = "backapi"
  network_mode                       = "awsvpc"
  cpu_limit                          = 512
  memory_limit                       = 1024
  volumes                            = {}
  scheduling_strategy                = "REPLICA"
  desired_count                      = 2
  health_check_grace_period_seconds  = 60
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50
  autoscaling_enabled                = true
  autoscaling_min_capacity           = 2
  autoscaling_max_capacity           = 4
  load_balancer_type                 = "internal"
  deregistration_delay               = 10
  logs_expire                        = 60
  listener_mappings = {
    fpm = {
      lb_protocol        = "TCP"
      lb_port            = 9006
      container_protocol = "TCP"
      container_port     = 9000
      ssl_policy         = null
      action             = "forward"
    }
  }
  container_definition = {
    name        = "backapi"
    image       = null
    mountPoints = []
    portMappings = [
      {
        containerPort = 9000
        hostPort      = 9000
        protocol      = "tcp"
      }
    ]
    ulimits = []
  }
}
