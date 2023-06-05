locals {
  ecs_cluster_name            = "<template:customer-env>-scheduler"
  ec2_instance_type           = "t3.medium"
  ec2_volume_type             = "gp2"
  ec2_volume_size             = 30
  cpu_credits                 = "standard"
  instance_market_options     = []
  autoscaling_min_size        = 1
  autoscaling_max_size        = 1
  autoscaling_target_capacity = 100
}
