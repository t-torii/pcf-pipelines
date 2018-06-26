#!/bin/bash

set -eu


# Should the slug contain more than one product, pick only the first.
FILE_PATH=`find ./pivnet-pas -name *.pivotal | sort | head -1`
echo $FILE_PATH
ls -l ./pivnet-pas

om-linux -t https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  -u "$OPS_MGR_USR" \
  -p "$OPS_MGR_PWD" \
  -k \
  --request-timeout 3600 \
  upload-product \
  -p $FILE_PATH
