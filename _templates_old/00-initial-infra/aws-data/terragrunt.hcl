include {
  path = find_in_parent_folders()
}
terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_data?ref=v8.0.0"
}

inputs = {
}
