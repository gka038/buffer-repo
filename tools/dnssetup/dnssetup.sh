#!/bin/bash

set -u

declare -A ZONE_ACCOUNTS
ZONE_ACCOUNTS["demo-spryker.com"]="893368928153"      # root account
ZONE_ACCOUNTS["cloud.spryker.toys"]="262925510123"    # sandbox
#ZONE_ACCOUNTS["cloud.spryker.systems"]="066672170623" # shared - we shouldnt use cloud.spryker.systems

TG_ZONE_DIR="${DIR}/00-initial-infra/route53/zone"
TG_CONFIG="${DIR}/config/common/spryker.hcl"
DNS_ZONE_RE='(?=^.{4,253}$)^(?:[^-][a-zA-Z0-9-]{1,63}[^-]\.){1,127}([^-][a-zA-Z0-9-]{1,63}[^-])$'
AWS_ACCOUNT_RE='^[0-9]{12}$'


function get_aws_account_id_from_config(){
  AWS_ACCOUNT_ID=$(cat ${TG_CONFIG} | awk '/aws_account_id/ {print $3}' | tr -d '"')
  ! [[ ${AWS_ACCOUNT_ID} =~ ${AWS_ACCOUNT_RE} ]] && { echo "ERROR: Incorrect AWS Account Id found in ${DIR}/config/common/spryker.hcl: $AWS_ACCOUNT_ID" 1>&2; exit 1; }

  echo $AWS_ACCOUNT_ID
}


function get_dns_zone_from_config(){
  ZONE=$(grep -w route53_zone_domain ${TG_CONFIG} | cut -d\" -f 2)
  [[ $? -ne 0 ]] || [[ $ZONE == "" ]] && { echo "ERROR: Could not extract route53_zone_domain from ${TG_CONFIG}" 1>&2; exit 1; }
  echo $ZONE | grep -iPq ${DNS_ZONE_RE} || { echo "ERROR: DNS zone ${ZONE} didnt pass regular expression check" 1>&2; exit 1; }

  echo $ZONE
}


function get_root_zone_name(){
  ZONE=$1

  ROOT_ZONE_NAME=$(echo $ZONE | awk '{ print substr($0, index($0, ".")+1) }')

  FOUND=0
  for i in ${!ZONE_ACCOUNTS[@]}; do
    echo $ROOT_ZONE_NAME | grep -qwi $i && FOUND=1
  done

  [[ $FOUND == 0 ]] && { echo "WARN: The root zone (${ROOT_ZONE_NAME}) of your requested zone (${ZONE}) not found in supported zones - skipping setup" 1>&2; exit 1; }

  echo ${ROOT_ZONE_NAME}
}


function get_root_zone_id(){
  ZONE=$1

  # check if root zone exists in specified account
  aws route53 list-hosted-zones-by-name --dns-name "${ZONE}" --max-items 1 --query 'HostedZones[*].Name' | grep -iq ${ZONE} || { echo "ERROR: Root Zone ${ZONE} doesnt exist in this account" 1>&2; exit 1; }

  # check get zone id
  ROOT_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "${ZONE}" --max-items 1 --query HostedZones[] | jq -r '.[0].Id') || { echo "ERROR: Could not get Root Zone ${ZONE} ID" 1>&2; exit 1; }

  echo ${ROOT_ZONE_ID}
}


function authenticate_to_aws_account(){
  AWS_ACCOUNT_ID=$1

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

  AUTHDATA=$(vault write aws/sts/${AWS_ACCOUNT_ID} ttl=60m) || { echo "ERROR: Could not assume role for account: $AWS_ACCOUNT_ID"; exit 1; }

  export AWS_ACCESS_KEY_ID=$(echo "$AUTHDATA" | awk '/access_key/ {print $2}')
  export AWS_SECRET_ACCESS_KEY=$(echo "$AUTHDATA" | awk '/secret_key/ {print $2}')
  export AWS_SESSION_TOKEN=$(echo "$AUTHDATA" | awk '/security_token/ {print $2}')
}


function create_dns_zone(){
  DNS_ZONE=$1

  aws route53 list-hosted-zones-by-name --dns-name "${DNS_ZONE}" --max-items 1 --query 'HostedZones[*].Name' | grep -iq ${DNS_ZONE} && { echo "NOTICE: Zone ${DNS_ZONE} already exists, skipping setup" 1>&2; exit 1; }
  ZONE_DATA=$(aws route53 create-hosted-zone --name ${DNS_ZONE} --caller-reference $(date +%s%N) | jq '{ "name": .HostedZone.Name, "id": .HostedZone.Id, "ns":  .DelegationSet.NameServers }') || { echo "ERROR: Could not create dns zone ${DNS_ZONE}" 1>&2; exit 1; }

  echo ${ZONE_DATA}
}

function delegate_zone(){
  ROOT_ZONE_ID=$1
  ZONE_DATA=$2

  aws route53 change-resource-record-sets --hosted-zone-id ${ROOT_ZONE_ID} --change-batch '
{
  "Comment": "Update NS-records to handle '$(echo ${ZONE_DATA} | jq -r .name)'",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$(echo ${ZONE_DATA} | jq -r .name)'",
        "Type": "NS",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "'$(echo ${ZONE_DATA} | jq -r .ns[0])'"
          },
          {
            "Value": "'$(echo ${ZONE_DATA} | jq -r .ns[1])'"
          },
          {
            "Value": "'$(echo ${ZONE_DATA} | jq -r .ns[2])'"
          },
          {
            "Value": "'$(echo ${ZONE_DATA} | jq -r .ns[3])'"
          }
        ]
      }
    }
  ]
}
' 1>/dev/null || { echo "ERROR: Could not create delegation records ${DNS_ZONE}" 1>&2; exit 1; }

}


function import_zone_into_tg(){
  ZONE_DATA=$1

  cd ${TG_ZONE_DIR}
  terragrunt state list | grep -q aws_route53_zone && { echo "ERROR: DNS zone already managed by Terragrunt"; exit 1; }

  terragrunt import aws_route53_zone.this $(echo ${ZONE_DATA} | jq -r .id) || { echo "ERROR: Could not import zone into Terragrunt"; exit 1; }

}



function main(){
  set -eo pipefail

  echo "Extracting AWS account id from the configuration file: $TG_CONFIG"
  ZONE_AWS_ACCOUNT_ID=$(get_aws_account_id_from_config)

  echo "Extracting DNS Zone name from the configuration file: $TG_CONFIG"
  DNS_ZONE_NAME=$(get_dns_zone_from_config)

  echo "Extracting root DNS zone name from the requested zone: $DNS_ZONE_NAME"
  ROOT_ZONE_NAME=$(get_root_zone_name ${DNS_ZONE_NAME}) || exit 0

  echo "Getting root DNS zone (${ROOT_ZONE_NAME}) AWS account id"
  ROOT_ZONE_AWS_ACCOUNT_ID=$(echo ${ZONE_ACCOUNTS[$ROOT_ZONE_NAME]})

  echo "Authenticating to AWS Account: $ZONE_AWS_ACCOUNT_ID"
  authenticate_to_aws_account ${ZONE_AWS_ACCOUNT_ID}

  echo "Creating DNS zone: $DNS_ZONE_NAME"
  ZONE_DATA=$(create_dns_zone ${DNS_ZONE_NAME}) || exit 0

  echo "Authenticating to AWS Account: $ROOT_ZONE_AWS_ACCOUNT_ID"
  authenticate_to_aws_account ${ROOT_ZONE_AWS_ACCOUNT_ID}

  echo "Getting ID of root DNS zone: $ROOT_ZONE_NAME"
  ROOT_ZONE_ID=$(get_root_zone_id ${ROOT_ZONE_NAME})

  echo "Creating delegation records for zone ${DNS_ZONE_NAME} in ${ROOT_ZONE_NAME}"
  delegate_zone ${ROOT_ZONE_ID} "${ZONE_DATA}"

  echo "Authenticating to AWS Account: $ZONE_AWS_ACCOUNT_ID"
  authenticate_to_aws_account ${ZONE_AWS_ACCOUNT_ID}

  echo "Importing zone ${DNS_ZONE_NAME} into Terragrunt"
  import_zone_into_tg "${ZONE_DATA}"
}

# main
main

exit 0
