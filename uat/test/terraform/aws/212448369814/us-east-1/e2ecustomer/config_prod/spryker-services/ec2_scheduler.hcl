locals {
  instance_name = "scheduler"
  settings = {
    size                        = "t3.medium"
    ebs_size                    = 50
    ebs_iops                    = 0
    ebs_type                    = "gp2"
    ebs_block_device_encrypted  = false
    root_block_type             = "gp2"
    root_block_size             = 10
    root_block_device_encrypted = false
  }
  sftp_enable          = false
  sftp_efs_mount_point = "/media/sftp-efs"
  cpu_credits          = "standard"  # Possible Values: standard, unlimited
  alarm_configuration = {
    alarm_name          = "jenkins-failure-alarm"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = "1"
    metric_name         = "HealthyHostCount"
    namespace           = "AWS/NetworkELB"
    period              = "60"
    statistic           = "Minimum"
    threshold           = 1.0
    alarm_description   = "Number of healthy nodes in Target Group"
    actions_enabled     = "true"
  }
}
