#!/bin/bash

set -uo pipefail

RE="^[0-9]{12}$"
SPRYKERCONF="${DIR}/config/common/spryker.hcl"


if ! [[ -f ${SPRYKERCONF} ]]; then
  echo "Required file ${SPRYKERCONF} doesnt exist"
  exit 1
fi

AWS_ACCOUNT_ID=$(cat ${SPRYKERCONF} | awk '/aws_account_id/ {print $3}' | tr -d '"')

if ! [[ ${AWS_ACCOUNT_ID} =~ ${RE} ]]; then
  echo "Incorrect AWS Account Id found in ${DIR}/config/common/spryker.hcl: $AWS_ACCOUNT_ID"
  exit 1
fi

AUTHDATA=$(vault write aws/sts/${AWS_ACCOUNT_ID} ttl=60m)
if [[ "$?" -ne 0 ]]; then
  echo "Could not assume role for account $AWS_ACCOUNT_ID"
  exit 1
fi

export AWS_ACCESS_KEY_ID=$(echo "$AUTHDATA" | awk '/access_key/ {print $2}')
export AWS_SECRET_ACCESS_KEY=$(echo "$AUTHDATA" | awk '/secret_key/ {print $2}')
export AWS_SESSION_TOKEN=$(echo "$AUTHDATA" | awk '/security_token/ {print $2}')

echo "Successfully assumed role for account: ${AWS_ACCOUNT_ID}"

set -u

FIRSTRUN=0

# create conf.d dir as a workaround (conf.d will be deprecated)
! [[ -d "${DIR}/../conf.d" ]] && unzip tools/artifacts/confd.zip -d "${DIR}/../"

# always refresh vault secrets before plan
cd ${DIR}/00-initial-infra/vault-secrets
terragrunt apply --auto-approve --terragrunt-non-interactive 2>&1 | tgstrip || exit 1
# terragrunt apply --auto-approve --terragrunt-non-interactive 2>$LOG_LOCATION/error_temp.log | tee $LOG_LOCATION/output_temp.log 

# check is this is a first run of the plan (check if example resource (route53/zone) exists
cd ${DIR}/00-initial-infra/route53/zone
terragrunt state list &>/dev/null || FIRSTRUN=1

if [[ "$FIRSTRUN" -eq 1 ]]; then
    echo "Running the first plan (initial environment provisioning) - please review all errors, exit code will be overridden to success"
    cd $DIR
    # override exit code 1 for first run to 0
    terragrunt run-all plan --terragrunt-ignore-dependency-errors --terragrunt-parallelism 6 2>&1 | tgstrip || true 
    # terragrunt run-all plan --terragrunt-ignore-dependency-errors --terragrunt-parallelism 6 2>&1 | tgstrip | tee $LOG_LOCATION/output.log || true
else
    cd $DIR
    terragrunt run-all plan --terragrunt-parallelism 6 2>&1 | tgstrip
    # terragrunt run-all plan --terragrunt-parallelism 6 2>&1 | tgstrip | tee $LOG_LOCATION/output.log 
fi
