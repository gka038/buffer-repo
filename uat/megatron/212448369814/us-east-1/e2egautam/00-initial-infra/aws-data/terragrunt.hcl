include {
  path = find_in_parent_folders()
}
terraform {
  source = "git@github.com:spryker-projects/tfcloud-modules.git//refactored/aws_data?ref=23_01.0"
}

inputs = {
}
