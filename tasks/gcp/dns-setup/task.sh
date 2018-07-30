#!/bin/bash
echo "==== gcloud configuration ===="
echo $GCP_SERVICE_KEY > /tmp/keyfile.json
gcloud auth activate-service-account --key-file /tmp/keyfile.json
gcloud config set project ${GCP_PROJECT_NAME}

gcloud compute --project "spartan-tesla-201301" ssh --zone "asia-east1-a" "jump-server" --quiet
ls
exit
