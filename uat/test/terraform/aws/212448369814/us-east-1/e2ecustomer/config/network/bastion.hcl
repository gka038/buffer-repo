locals {
  instance_name                           = "bastion"
  settings                                = {
    size                       = "t3a.micro"
    ebs_size                   = 10
    ebs_iops                   = 0
    ebs_type                   = "gp3"
    ebs_block_device_encrypted = false
  }
  vpn_cidr                                = "10.8.0.0/24"
  sftp_enable                             = true
  custom_sftp_user                        = {
    name = "<template:change_me>"
    path = "<template:change_me>"
  }
  efs_infrequent_access_transition_policy = "AFTER_90_DAYS"
  cpu_credits                             = "standard" # Possible Values: standard, unlimited
}
