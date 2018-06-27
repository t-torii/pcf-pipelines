#!/bin/bash
set -e

source "pcf-pipelines/functions/check_opsman_available.sh"

ifconfig
cat /etc/resolv.conf
dig ${OPSMAN_DOMAIN_OR_IP_ADDRESS}

opsman_available=$(check_opsman_available "${OPSMAN_DOMAIN_OR_IP_ADDRESS}")
if [[ $opsman_available != "available" ]]; then
  echo Could not reach ${OPSMAN_DOMAIN_OR_IP_ADDRESS}. Is DNS set up correctly?
  exit 1
fi
