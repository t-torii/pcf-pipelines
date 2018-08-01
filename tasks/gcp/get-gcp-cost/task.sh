#!/bin/bash
set -eu

echo "==== gcloud configuration ===="
echo $GCP_SERVICE_KEY > /tmp/keyfile.json
gcloud auth activate-service-account --key-file /tmp/keyfile.json
gcloud config set project ${GCP_PROJECT_NAME}

files=$(gsutil ls "gs://${TERRAFORM_STATEFILE_BUCKET}")

if [ $(echo $files | grep -c gcpbilling.json) == 0 ]; then
  echo "{\"version\": 3}" > gcpbilling.json
  gsutil cp gcpbilling.json "gs://${TERRAFORM_STATEFILE_BUCKET}/gcpbilling.json"
else
  echo "gcpbilling.json file found, skipping"
fi

billing="[]"
length=0

while :
do
  billingTemp=$(gcloud beta pubsub subscriptions pull projects/spartan-tesla-201301/subscriptions/gcp-billing-sub --format json --quiet --auto-ack)
  length=$(echo $billingTemp | jq '. | length')
  echo "length = $length"
  if [ $length -eq 0 ]; then
    echo "break"
    break;
  fi
  billing=$(echo $billingTemp)
  echo $billing | jq '.'
  cost=$(echo $billing | jq -r '.[].message.data' | base64 -d |  jq '.costAmount')
  echo "cost = $cost"
done

length=$(echo $billing | jq '. | length')
echo "length = $length"
if [ $length -gt 0 ]; then
  echo "=== copy new billing data to gs://${TERRAFORM_STATEFILE_BUCKET}/gcpbilling.json"
  echo $billing > gcpbilling.json
  gsutil cp gcpbilling.json "gs://${TERRAFORM_STATEFILE_BUCKET}/gcpbilling.json"
fi

cost=$(gsutil cat "gs://${TERRAFORM_STATEFILE_BUCKET}/gcpbilling.json" | jq -r '.[].message.data' | base64 -d |  jq '.costAmount')

echo "cost = $cost"

if [ $cost -gt $COST_UPPER_LIMIT ]; then
  echo "cost($cost) reaches upperlimit($COST_UPPER_LIMIT)!"
  exit 1
fi
