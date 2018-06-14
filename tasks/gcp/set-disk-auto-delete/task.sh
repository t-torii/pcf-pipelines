#!/bin/bash

main(){
  echo "==== gcloud configuration ===="
  echo $GCP_SERVICE_KEY > /tmp/keyfile.json
  gcloud auth activate-service-account --key-file /tmp/keyfile.json
  gcloud config set project ${GCP_PROJECT_NAME}

  echo -e "\n==== gcloud compute list ===="
  gcloud compute instances list

  search_vm master
  search_vm worker
  search_vm pivotal-container-service

}

search_vm(){
  echo -e "\n==== search $1 vm ===="
  filter=`echo labels.instance_group=$1`
  export vms=$(gcloud compute instances list --filter='$filter' \
    --format=json | jq -r '.[] | .name')
  echo "vms = $vms"
  if [ $vms = ""]; then
    echo "$1 can't found!"
    return
  fi

  for vm in $vms
  do
    set_disk_auto_delete $vm
  done
}

set_disk_auto_delete(){
  echo -e "\n==== search disks of $1 ===="
  export disks=$(gcloud compute instances describe $1 \
    --format=json | jq -r '.disks[].deviceName')
  echo "disks = $disks"
  for disk in $disks
  do
    gcloud compute instances set-disk-auto-delete $1 --disk=$disk
  done

}

main
