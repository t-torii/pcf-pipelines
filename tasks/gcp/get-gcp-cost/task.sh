#!/bin/bash
echo "==== gcloud configuration ===="
echo $GCP_SERVICE_KEY > /tmp/keyfile.json
gcloud auth activate-service-account --key-file /tmp/keyfile.json
gcloud config set project ${GCP_PROJECT_NAME}

gcloud beta pubsub subscriptions pull projects/spartan-tesla-201301/subscriptions/gcp-billing-sub

export cost_amount=$(gcloud beta pubsub subscriptions pull \
projects/spartan-tesla-201301/subscriptions/gcp-billing-sub --format json --quiet \
| jq -r '.[].message.data' | base64 -d |  jq '.costAmount')

echo "cost = $(cost_amount)"
