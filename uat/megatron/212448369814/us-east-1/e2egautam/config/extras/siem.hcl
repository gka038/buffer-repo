locals {
  # The log group name where to send SSM logs to
  ssm_log_group_name = "/aws/ssm/audit"

  # Enables the CWL subscriptions into the Managed SOC account
  #
  # NOTE!: Please enable cwl subscriptions **after** a successful deployment
  # of an environment as this will fetch **all** of the log groups **on per region basis**
  # and subscribe them.
  enable_cwl_subscriptions = false

  # Enables forwarding of Session Manager audit logs to the Managed SOC account
  #
  # NOTE!: This needs to be enabled on region basis as the document along with cloudwatch logs
  # are regional services.
  enable_ssm_s3_audit = false

  # Enables creation of IAM roles for Kinesis Firehose streaming of log events.
  enable_cwl_subscriptions_roles = false
}
