#!/bin/bash
echo "==== gcloud configuration ===="
echo $GCP_SERVICE_KEY > /tmp/keyfile.json
gcloud auth activate-service-account --key-file /tmp/keyfile.json
gcloud config set project ${GCP_PROJECT_NAME}

echo -e "\n==== gcloud compute list ===="
gcloud compute instances list

echo -e "\n==== get kubenetes master vm ===="
export pks-api-vm=$(gcloud compute instances list --filter='labels.instance_group=pivotal-container-service' \
 --format=json | jq -r '.[] | .name')
echo "pks-api-vm = ${pks-api-vm}"
if [ $pks-api-vm = "" ]; then
  echo "pks-api-vm can't found!"
  exit 1
fi

echo -e "\n==== add firewall rule to master vm ===="
gcloud compute instances add-tags ${pks-api-vm} --tags="${GCP_RESOURCE_PREFIX}-pks-api" --zone=${GCP_ZONE}

echo -e "\n==== loadbalancer check ===="
gcloud compute target-pools describe ${GCP_RESOURCE_PREFIX}-pks-api --region=${GCP_REGION}

echo -e "\n==== add master vm to loadbalancer ===="
gcloud compute target-pools add-instances ${GCP_RESOURCE_PREFIX}-pks-api \
 --instances=${pks-api-vm} --instances-zone=${GCP_ZONE}

echo -e "\n==== loadbalancer check ===="
gcloud compute target-pools describe ${GCP_RESOURCE_PREFIX}-pks-api --region=${GCP_REGION}
