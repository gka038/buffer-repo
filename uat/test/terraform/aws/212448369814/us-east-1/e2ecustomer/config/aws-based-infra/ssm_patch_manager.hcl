locals {
  patch_schedule_critical    = "cron(30 * ? * * *)" # Every hour, minute 30
  patch_schedule_noncritical = "cron(0 0 1 * ? *)"  # First day of the month, time 12:00 night
  reboot_option              = "RebootIfNeeded"     # Options: RebootIfNeeded, NoReboot
  s3 = {
    enabled = false
  }
  cloudwatch = {
    enabled                = false
    log_group_rotation_day = 30
  }
}
