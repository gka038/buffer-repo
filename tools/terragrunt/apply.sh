#!/bin/bash

set -uo pipefail

cd $DIR
terragrunt run-all apply --terragrunt-non-interactive --terragrunt-parallelism 6 2>&1 | tgstrip
