include {
  path = find_in_parent_folders()
}
terraform {
  source = "git@github.com:spryker/tfcloud-modules.git//refactored/aws_data?ref=23_02.0"
}

inputs = {
}
