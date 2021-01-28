#!/bin/bash

# This script is intended to delete an image from a local Docker registry
# Receives:
#  registry name: container name of the registry
#  registry: registry ip anmd port
#  name: image name

registry_name=$1
registry=$(echo $2 | egrep -o "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\:[0-9]{1,4}$")
name=$3

# show usage
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
  then
    echo "Usage: delete-image-registry.sh <registry-name> <ip:port> <image-name>"
    exit 1
fi

# print input info as feedback
echo "[INFO] Registry name = ${registry_name}"
echo "[INFO] IP:PORT = ${registry}"
echo "[INFO] Image name = ${name}"
echo "[WARN] ALWAYS MAKE SURE TO RUN ON HOST"

# check if docker container exist
if [ -z $(docker ps -a | grep ${registry_name}) ]
  then
    echo "[ERROR] Container doesn't exist"
    exit 1
fi

# proceed to delete image from registry using api
curl -v -sSL -X DELETE "http://${registry}/v2/${name}/manifests/$(curl -sSL -I \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    "http://${registry}/v2/${name}/manifests/$( \
      curl -sSL "http://${registry}/v2/${name}/tags/list" | jq -r '.tags[0]' )" \
  | awk '$1 == "Docker-Content-Digest:" { print $2 }' \
  | tr -d $'\r' \
)"

# ensure image is removed from catalog
docker exec -it ${registry_name} sh -c \
  "rm -r /var/lib/registry/docker/registry/v2/repositories/${name}/"

# run garbage collector
docker exec -it ${registry_name} \
  bin/registry garbage-collect /etc/docker/registry/config.yml
