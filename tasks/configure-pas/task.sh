#!/bin/bash

set -euo pipefail

echo "start configure-pas"
nslookup ${OPSMAN_DOMAIN_OR_IP_ADDRESS}

source pcf-pipelines/functions/generate_cert.sh
echo "check #1"

declare networking_poe_ssl_certs_json

saml_domains=(
  "*.${SYSTEM_DOMAIN}"
  "*.login.${SYSTEM_DOMAIN}"
  "*.uaa.${SYSTEM_DOMAIN}"
)
echo "check #2"
saml_certificates=$(generate_cert "${saml_domains[*]}")
saml_cert_pem=`echo $saml_certificates | jq --raw-output '.certificate'`
saml_key_pem=`echo $saml_certificates | jq --raw-output '.key'`

function isPopulated() {
    local true=0
    local false=1
    local envVar="${1}"

    if [[ "${envVar}" == "" ]]; then
        return ${false}
    elif [[ "${envVar}" == null ]]; then
        return ${false}
    else
        return ${true}
    fi
}

function formatCredhubEncryptionKeysJson() {
    local credhub_encryption_key_name1="${1}"
    local credhub_encryption_key_secret1=${2//$'\n'/'\n'}
    local credhub_primary_encryption_name="${3}"
    credhub_encryption_keys_json="{
            \"name\": \"$credhub_encryption_key_name1\",
            \"key\":{
                \"secret\": \"$credhub_encryption_key_secret1\"
             }"
    if [[ "${credhub_primary_encryption_name}" == $credhub_encryption_key_name1 ]]; then
        credhub_encryption_keys_json="$credhub_encryption_keys_json, \"primary\": true}"
    else
        credhub_encryption_keys_json="$credhub_encryption_keys_json}"
    fi
    echo "$credhub_encryption_keys_json"
}

credhub_encryption_keys_json=$(formatCredhubEncryptionKeysJson "${CREDUB_ENCRYPTION_KEY_NAME1}" "${CREDUB_ENCRYPTION_KEY_SECRET1}" "${CREDHUB_PRIMARY_ENCRYPTION_NAME}")
if isPopulated "${CREDUB_ENCRYPTION_KEY_NAME2}"; then
    credhub_encryption_keys_json2=$(formatCredhubEncryptionKeysJson "${CREDUB_ENCRYPTION_KEY_NAME2}" "${CREDUB_ENCRYPTION_KEY_SECRET2}" "${CREDHUB_PRIMARY_ENCRYPTION_NAME}")
    credhub_encryption_keys_json="$credhub_encryption_keys_json,$credhub_encryption_keys_json2"
fi
if isPopulated "${CREDUB_ENCRYPTION_KEY_NAME3}"; then
    credhub_encryption_keys_json3=$(formatCredhubEncryptionKeysJson "${CREDUB_ENCRYPTION_KEY_NAME3}" "${CREDUB_ENCRYPTION_KEY_SECRET3}" "${CREDHUB_PRIMARY_ENCRYPTION_NAME}")
    credhub_encryption_keys_json="$credhub_encryption_keys_json,$credhub_encryption_keys_json3"
fi
credhub_encryption_keys_json="[$credhub_encryption_keys_json]"

if [[ "${pcf_iaas}" == "gcp" ]]; then
  cd terraform-state
    pcf_ert_ssl_cert="$(terraform output -json ert_certificate | jq .value)"
    pcf_ert_ssl_key="$(terraform output -json ert_certificate_key | jq .value)"
  cd -

  networking_poe_ssl_certs_json="[
    {
      \"name\": \"Certificate 1\",
      \"certificate\": {
        \"cert_pem\": $pcf_ert_ssl_cert,
        \"private_key_pem\": $pcf_ert_ssl_key
      }
    }
  ]"
fi

cf_network=$(
  jq -n \
    --arg singleton_availability_zone "$pcf_az_1" \
    --arg other_availability_zones "$pcf_az_1,$pcf_az_2,$pcf_az_3" \
    '
    {
      "network": {
        "name": "pks",
      },
      "other_availability_zones": ($other_availability_zones | split(",") | map({name: .})),
      "singleton_availability_zone": {
        "name": $singleton_availability_zone
      }
    }
    '
)

cf_resources=$(
  jq -n \
    --arg terraform_prefix $terraform_prefix \
    --argjson internet_connected $INTERNET_CONNECTED \
    '
    {
      "backup-prepare": {"internet_connected": $internet_connected},
      "clock_global": {"internet_connected": $internet_connected},
      "cloud_controller": {"internet_connected": $internet_connected},
      "cloud_controller_worker": {"internet_connected": $internet_connected},
      "consul_server": {"internet_connected": $internet_connected},
      "credhub": {"internet_connected": $internet_connected},
      "diego_brain": {"internet_connected": $internet_connected},
      "diego_cell": {"internet_connected": $internet_connected},
      "diego_database": {"internet_connected": $internet_connected},
      "doppler": {"internet_connected": $internet_connected},
      "ha_proxy": {"internet_connected": $internet_connected},
      "loggregator_trafficcontroller": {"internet_connected": $internet_connected},
      "mysql": {"instances": 0, "internet_connected": $internet_connected},
      "mysql_monitor": {"instances": 0, "internet_connected": $internet_connected},
      "mysql_proxy": {"instances": 0, "internet_connected": $internet_connected},
      "nats": {"internet_connected": $internet_connected},
      "nfs_server": {"internet_connected": $internet_connected},
      "router": {"internet_connected": $internet_connected},
      "syslog_adapter": {"internet_connected": $internet_connected},
      "syslog_scheduler": {"internet_connected": $internet_connected},
      "tcp_router": {"internet_connected": $internet_connected},
      "uaa": {"internet_connected": $internet_connected}
    }

    |

    # ELBs

    .router |= . + { "elb_names": ["http:\($terraform_prefix)-http-lb-backend","tcp:\($terraform_prefix)-wss-logs"] }
    | .diego_brain |= . + { "elb_names": ["tcp:\($terraform_prefix)-ssh-proxy"] }
    '
)

cf_properties=$(
  jq -n \
    --arg terraform_prefix $terraform_prefix \
    --arg singleton_availability_zone "$pcf_az_1" \
    --arg other_availability_zones "$pcf_az_1,$pcf_az_2,$pcf_az_3" \
    --arg saml_cert_pem "$saml_cert_pem" \
    --arg saml_key_pem "$saml_key_pem" \
    --arg haproxy_forward_tls "$HAPROXY_FORWARD_TLS" \
    --arg haproxy_backend_ca "$HAPROXY_BACKEND_CA" \
    --arg router_tls_ciphers "$ROUTER_TLS_CIPHERS" \
    --arg haproxy_tls_ciphers "$HAPROXY_TLS_CIPHERS" \
    --arg frontend_idle_timeout "$FRONTEND_IDLE_TIMEOUT" \
    --arg routing_disable_http "$routing_disable_http" \
    --arg routing_custom_ca_certificates "$ROUTING_CUSTOM_CA_CERTIFICATES" \
    --arg routing_tls_termination $ROUTING_TLS_TERMINATION \
    --arg system_domain "$SYSTEM_DOMAIN"\
    --arg apps_domain "$APPS_DOMAIN" \
    --arg mysql_monitor_recipient_email "$mysql_monitor_recipient_email" \
    --arg gcp_storage_access_key "${gcp_storage_access_key:-''}" \
    --arg gcp_storage_secret_key "${gcp_storage_secret_key:-''}" \
    --argjson credhub_encryption_keys "$credhub_encryption_keys_json" \
    --argjson networking_poe_ssl_certs "$networking_poe_ssl_certs_json" \
    --arg container_networking_nw_cidr "$CONTAINER_NETWORKING_NW_CIDR" \
    '
    {
      ".uaa.service_provider_key_credentials": {
        "value": {
          "cert_pem": $saml_cert_pem,
          "private_key_pem": $saml_key_pem
        }
      },
      ".properties.tcp_routing": { "value": "disable" },
      ".properties.route_services": { "value": "enable" },
      ".ha_proxy.skip_cert_verify": { "value": true },
      ".properties.container_networking_interface_plugin.silk.network_cidr": { "value": $container_networking_nw_cidr },
      ".properties.route_services.enable.ignore_ssl_cert_verification": { "value": true },
      ".properties.system_database": { "value": "internal_mysql" },
      ".properties.uaa_database": { "value": "internal_mysql" },
      ".properties.push_apps_manager_company_name": { "value": "pcf" },
      ".cloud_controller.system_domain": { "value": $system_domain },
      ".cloud_controller.apps_domain": { "value": $apps_domain },
      ".cloud_controller.allow_app_ssh_access": { "value": true },
      ".cloud_controller.security_event_logging_enabled": { "value": true },
      ".router.disable_insecure_cookies": { "value": false },
      ".router.frontend_idle_timeout": { "value": $frontend_idle_timeout },
      ".mysql_monitor.recipient_email": { "value" : $mysql_monitor_recipient_email }
    }

    +

    # Credhub encryption keys
    {
      ".properties.credhub_key_encryption_passwords": {
        "value": $credhub_encryption_keys
      }
    }

    +

    # logger_endpoint_port
    # Blobstore

      {
        ".properties.system_blobstore": { "value": "internal" },
      }

    +

    # SSL Termination
    {
      ".properties.networking_poe_ssl_certs": {
        "value": $networking_poe_ssl_certs
      }
    }

    +

    # HAProxy Forward TLS
    if $haproxy_forward_tls == "enable" then
      {
        ".properties.haproxy_forward_tls": {
          "value": "enable"
        },
        ".properties.haproxy_forward_tls.enable.backend_ca": {
          "value": $haproxy_backend_ca
        }
      }
    else
      {
        ".properties.haproxy_forward_tls": {
          "value": "disable"
        }
      }
    end

    +

    {
      ".properties.routing_disable_http": {
        "value": $routing_disable_http
      }
    }

    +

    if $routing_custom_ca_certificates == "" then
      .
    else
      {
        ".properties.routing_custom_ca_certificates": {
          "value": $routing_custom_ca_certificates
        }
      }
    end

    +

    {
      ".properties.routing_tls_termination": {
        "value": $routing_tls_termination
      }
    }

    +

    # TLS Cipher Suites
    {
      ".properties.gorouter_ssl_ciphers": {
        "value": $router_tls_ciphers
      },
      ".properties.haproxy_ssl_ciphers": {
        "value": $haproxy_tls_ciphers
      }
    }
    '
)

om-linux \
  --target https://$OPSMAN_DOMAIN_OR_IP_ADDRESS \
  --username "$OPS_MGR_USR" \
  --password "$OPS_MGR_PWD" \
  --skip-ssl-validation \
  configure-product \
  --product-name cf \
  --product-properties "$cf_properties" \
  --product-network "$cf_network" \
  --product-resources "$cf_resources"
