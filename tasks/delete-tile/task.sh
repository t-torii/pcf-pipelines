#!/bin/bash
set -eu

main() {
  if [ -n $OPSMAN_IP ]; then
    echo "$OPSMAN_IP $OPSMAN_DOMAIN_OR_IP_ADDRESS" >> /etc/hosts
  fi

  # find tile version installed
  echo "Retrieving current staged version of ${TILE_PRODUCT_NAME}"
  product_version=$(om-linux \
    --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    --skip-ssl-validation  \
    deployed-products | grep ${TILE_PRODUCT_NAME} | cut -d "|" -f 3 | tr -d " ")

  echo "Unsteging product [${TILE_PRODUCT_NAME}], version [${product_version}] , from ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"

  om-linux \
    --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
    --username "$OPSMAN_USERNAME" \
    --password "$OPSMAN_PASSWORD" \
    --skip-ssl-validation \
    unstage-product \
    --product-name "$TILE_PRODUCT_NAME"

}

main
