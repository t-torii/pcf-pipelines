#!/bin/bash
echo "==== gcloud configuration ===="
echo $GCP_SERVICE_KEY > /tmp/keyfile.json
gcloud auth activate-service-account --key-file /tmp/keyfile.json
gcloud config set project ${GCP_PROJECT_NAME}

echo -e "\n==== gcloud compute list ===="
gcloud compute instances list

echo -e "\n==== get kubenetes master vm ===="
export master_vm=$(gcloud compute instances list --filter='tags.items=master' \
 --format=json | jq -r '.[] | .name')
echo "master_vm = ${master_vm}"
if [ $master_vm = "" ]; then
  echo "master_vm can't found!"
  exit 1
fi

# echo -e "\n==== add firewall rule to master vm ===="
# gcloud compute instances add-tags ${master_vm} --tags="pks-kubectl" --zone=${GCP_ZONE}

echo -e "\n==== loadbalancer create ===="
gcloud compute target-pools create ${GCP_RESOURCE_PREFIX}-master --region=${GCP_REGION}
gcloud compute forwarding-rules create ${GCP_RESOURCE_PREFIX}-master-8443 --region=${GCP_REGION} \
--target-pool=${GCP_RESOURCE_PREFIX}-master --ip-protocol=tcp --ports=8443
gcloud compute target-pools describe ${GCP_RESOURCE_PREFIX}-master --region=${GCP_REGION}

echo -e "\n==== add master vm to loadbalancer ===="
gcloud compute target-pools add-instances ${GCP_RESOURCE_PREFIX}-master \
 --instances=${master_vm} --instances-zone=${GCP_ZONE}

echo -e "\n==== loadbalancer check ===="
gcloud compute target-pools describe ${GCP_RESOURCE_PREFIX}-master --region=${GCP_REGION}
