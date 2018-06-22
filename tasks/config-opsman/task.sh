#!/bin/bash

set -eu

if [[ $BYPASS = true ]]; then
  echo "Bypassing the task"
  exit 0
fi

nslookup $OPSMAN_DOMAIN_OR_IP_ADDRESS

until $(curl --output /dev/null -k --silent --head --fail https://$OPSMAN_DOMAIN_OR_IP_ADDRESS/setup); do
    printf '.'
    sleep 5
done

om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  configure-authentication \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --decryption-passphrase $OM_DECRYPTION_PWD
