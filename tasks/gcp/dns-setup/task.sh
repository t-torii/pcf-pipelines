#!/bin/bash

cd terraform-state
  pub_ip_global_pcf=$(echo ./terraform.tfstate | jq --raw-output '.pub_ip_global_pcf.value')
  pub_ip_ssh_and_doppler=$(echo ./terraform.tfstate | jq --raw-output '.pub_ip_ssh_and_doppler.value')
  pub_ip_ssh_tcp_lb=$(echo ./terraform.tfstate | jq --raw-output '.pub_ip_ssh_tcp_lb.value')
  pub_ip_opsman=$(echo ./terraform.tfstate | jq --raw-output '.pub_ip_opsman.value')
  pub_ip_pks_api=$(echo ./terraform.tfstate | jq --raw-output '.pub_ip_pks_api.value')
cd -

echo "Please configure DNS as follows:"
echo "----------------------------------------------------------------------------------------------"
echo "${OPSMAN_DOMAIN_OR_IP_ADDRESS} == ${pub_ip_opsman}"
echo "api.pks.${PCF_ERT_DOMAIN} == ${pub_ip_pks_api}"
echo "*.${SYSTEM_DOMAIN} == ${pub_ip_global_pcf}"
echo "*.${APPS_DOMAIN} == ${pub_ip_global_pcf}"
echo "doppler.${SYSTEM_DOMAIN} == ${pub_ip_ssh_and_doppler}"
echo "loggregator.${SYSTEM_DOMAIN} == ${pub_ip_ssh_and_doppler}"
echo "----------------------------------------------------------------------------------------------"


echo "==== gcloud configuration ===="
echo $GCP_SERVICE_KEY > /tmp/keyfile.json
gcloud auth activate-service-account --key-file /tmp/keyfile.json
gcloud config set project ${GCP_PROJECT_NAME}


echo "==== dnsmasq restart ===="
gcloud compute --project "spartan-tesla-201301" ssh --zone "asia-east1-a" "jump-server" --quiet --command \
"sudo service dnsmasq restart"

echo "==== restore resolv.conf ===="
gcloud compute --project "spartan-tesla-201301" ssh --zone "asia-east1-a" "jump-server" --quiet --command \
"sudo cp /etc/resolv.conf.bak /etc/resolv.conf"
