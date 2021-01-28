#!/bin/bash

# This script is intended to delete a tag from a local Docker registry
# Receives:
#  registry name: container name of the registry
#  registry: registry ip anmd port
#  name: image name
#  tag: image tag

# receive arguments
registry_name=$1
registry=$(echo $2 | egrep -o "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\:[0-9]{1,4}$")
name=$3
tag=$4

# show usage
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]
  then
    echo "Usage: delete-tag-registry.sh <registry-name> <ip:port> <image-name> <image-tag>"
    exit 1
fi

# print input info as feedback
echo "[INFO] Registry name = ${registry_name}"
echo "[INFO] IP:PORT = ${registry}"
echo "[INFO] Image name = ${name}"
echo "[INFO] Tag name = ${tag}"
echo " "
echo "[WARN] ALWAYS MAKE SURE TO RUN ON HOST"
echo " "

# check if docker container exist
if [ -z $(docker ps -a | grep ${registry_name}) ]
  then
    echo -e "\n[ERROR] Container doesn't exist"
    exit 1
fi

# proceed to delete image from registry using api
echo -e "\n[INFO] Deleting from registry"
curl -v -sSL -X DELETE "http://${registry}/v2/${name}/manifests/$(curl -sSL -I \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    "http://${registry}/v2/${name}/manifests/${tag}" \
  | awk '$1 == "Docker-Content-Digest:" { print $2 }' \
  | tr -d $'\r' \
)"

# run garbage collector
echo -e "\n[INFO] Running garbage collector"
docker exec -it ${registry_name} \
  bin/registry garbage-collect /etc/docker/registry/config.yml
