locals {
  spryker_repo_conf = {
    type           = "github" # for codecommit change to "codecommit" and set correctly below codecommit parameters
    connection_arn = ""
    description    = "Repository for app"
    # github version
    owner  = "spryker"
    repo   = "b2b-demo-shop-internal"
    branch = "<template:customer-env>"
    repo_type = "nonsplit" # parameter for e2e tests. Now possible options are "nonsplit" and "b2b"
    # codecommit parameters
    mirror_exist             = false
    generate_ssh_credentials = false
  }

  spryker_sdk_repo   = "https://github.com/spryker/docker-sdk"
  spryker_sdk_branch = "master"
}
