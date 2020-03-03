#!/bin/bash

# This script reads the .env file, builds the image and pushes it to DockerHub
#
# Example:
#  push-to-registry.sh

set -e

set -a
. ./.env
set +a

echo "Building $IMAGE_FULL_TAG ..."

docker build $DOCKER_BUILD_EXTRA_ARGS \
  --build-arg build_date=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg build_base_image=$BASE_IMAGE \
  --build-arg build_distro_version=$XP_VERSION \
  -t $IMAGE_FULL_TAG \
  . 

for p in $PUSH_TO
do
  echo "Pushing $p ..."
  docker tag $IMAGE_FULL_TAG $p
  docker push $p
done