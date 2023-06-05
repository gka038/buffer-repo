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
