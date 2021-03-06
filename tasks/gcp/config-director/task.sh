#!/bin/bash

set -eu

iaas_configuration=$(
  jq -n \
    --arg gcp_project "$GCP_PROJECT_ID" \
    --arg default_deployment_tag "$GCP_RESOURCE_PREFIX" \
    --arg google_service_account "$GCP_SERVICE_ACCOUNT_EMAIL" \
    '
    {
      "project": $gcp_project,
      "default_deployment_tag": $default_deployment_tag,
      "associated_service_account": $google_service_account
    }
    '
)

availability_zones="${GCP_ZONE_1},${GCP_ZONE_2},${GCP_ZONE_3}"

az_configuration=$(
  jq -n \
    --arg availability_zones "$availability_zones" \
    '$availability_zones | split(",") | map({name: .})'
)

network_configuration=$(
  jq -n \
    --argjson icmp_checks_enabled false \
    --arg infra_network_name "infrastructure" \
    --arg infra_vcenter_network "${GCP_RESOURCE_PREFIX}-virt-net/${GCP_RESOURCE_PREFIX}-subnet-infrastructure-${GCP_REGION}/${GCP_REGION}" \
    --arg infra_network_cidr "192.168.101.0/26" \
    --arg infra_reserved_ip_ranges "192.168.101.1-192.168.101.9" \
    --arg infra_dns "${JUMP_SERVER_IP_ADDRESS}" \
    --arg infra_gateway "192.168.101.1" \
    --arg infra_availability_zones "$availability_zones" \
    --arg deployment_network_name "pks" \
    --arg deployment_vcenter_network "${GCP_RESOURCE_PREFIX}-virt-net/${GCP_RESOURCE_PREFIX}-subnet-pks-${GCP_REGION}/${GCP_REGION}" \
    --arg deployment_network_cidr "192.168.16.0/22" \
    --arg deployment_reserved_ip_ranges "192.168.16.1-192.168.16.9" \
    --arg deployment_dns "${JUMP_SERVER_IP_ADDRESS}" \
    --arg deployment_gateway "192.168.16.1" \
    --arg deployment_availability_zones "$availability_zones" \
    --arg services_network_name "services" \
    --arg services_vcenter_network "${GCP_RESOURCE_PREFIX}-virt-net/${GCP_RESOURCE_PREFIX}-subnet-services-${GCP_REGION}/${GCP_REGION}" \
    --arg services_network_cidr "192.168.20.0/22" \
    --arg services_reserved_ip_ranges "192.168.20.1-192.168.20.9" \
    --arg services_dns "${JUMP_SERVER_IP_ADDRESS}" \
    --arg services_gateway "192.168.20.1" \
    --arg services_availability_zones "$availability_zones" \
    '
    {
      "icmp_checks_enabled": $icmp_checks_enabled,
      "networks": [
        {
          "name": $infra_network_name,
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $infra_vcenter_network,
              "cidr": $infra_network_cidr,
              "reserved_ip_ranges": $infra_reserved_ip_ranges,
              "dns": $infra_dns,
              "gateway": $infra_gateway,
              "availability_zone_names": ($infra_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $deployment_network_name,
          "service_network": false,
          "subnets": [
            {
              "iaas_identifier": $deployment_vcenter_network,
              "cidr": $deployment_network_cidr,
              "reserved_ip_ranges": $deployment_reserved_ip_ranges,
              "dns": $deployment_dns,
              "gateway": $deployment_gateway,
              "availability_zone_names": ($deployment_availability_zones | split(","))
            }
          ]
        },
        {
          "name": $services_network_name,
          "service_network": true,
          "subnets": [
            {
              "iaas_identifier": $services_vcenter_network,
              "cidr": $services_network_cidr,
              "reserved_ip_ranges": $services_reserved_ip_ranges,
              "dns": $services_dns,
              "gateway": $services_gateway,
              "availability_zone_names": ($services_availability_zones | split(","))
            }
          ]
        }
      ]
    }'
)

director_config=$(cat <<-EOF
{
  "ntp_servers_string": "metadata.google.internal",
  "resurrector_enabled": true,
  "retry_bosh_deploys": true,
  "database_type": "internal",
  "blobstore_type": "local",
  "post_deploy_enabled": true
}
EOF
)

resource_configuration=$(cat <<-EOF
{
  "director": {
    "internet_connected": false
  },
  "compilation": {
    "internet_connected": false
  }
}
EOF
)

security_configuration=$(
  jq -n \
    --arg trusted_certificates "$OPS_MGR_TRUSTED_CERTS" \
    '
    {
      "trusted_certificates": $trusted_certificates,
      "vm_password_type": "generate"
    }'
)

network_assignment=$(
  jq -n \
    --arg availability_zones "$availability_zones" \
    --arg network "infrastructure" \
    '
    {
      "singleton_availability_zone": {
        "name": ($availability_zones | split(",") | .[0])
      },
      "network": {
        "name": $network
      }
    }'
)

echo "Checking OpsManager Access..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  available-products

echo "Configuring IaaS..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --iaas-configuration "$iaas_configuration"

echo "Configuring Director..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --director-configuration "$director_config"

echo "Configuring AZ..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --az-configuration "$az_configuration"

echo "Configuring Networks..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --networks-configuration "$network_configuration"

echo "Configuring Network Assignment..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --network-assignment "$network_assignment"

echo "Configuring Security Consideration..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --security-configuration "$security_configuration"

echo "Configuring Resource Configuration..."
om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --skip-ssl-validation \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  configure-director \
  --resource-configuration "$resource_configuration"
