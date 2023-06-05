include {
  path = find_in_parent_folders()
}

locals {
  spryker         = read_terragrunt_config(find_in_parent_folders("config/common/spryker.hcl"))
  aws-based-infra = read_terragrunt_config(find_in_parent_folders("config/aws-based-infra/lambda.hcl"))
}

terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/lambda/asg_scaling?ref=development"
}

skip = !local.aws-based-infra.locals.asg_scaling_enabled

dependency "lambda" {
  config_path = find_in_parent_folders("00-initial-infra/iam/lambda")

  mock_outputs = {
    lambda_iam_role_arn = "arn:aws:iam::123456789012:mock"
  }
}

inputs = {
  lambda_iam_role_arn   = dependency.lambda.outputs.lambda_iam_role_arn
  downscaling_schedule = local.aws-based-infra.locals.downscaling_schedule
  upscaling_schedule   = local.aws-based-infra.locals.upscaling_schedule
  asg_config            = local.aws-based-infra.locals.asg_config
}
