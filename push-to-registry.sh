#!/bin/bash
source ./env

echo $IMAGE_NAME
echo $IMAGE_TAG
echo $DOCKER_REGISTRY

function checkReturn() {
  status=$1
  msg=$2
  if [[ $status != 0 ]]; then
    echo "Failed: $msg"
    exit $rc;
  fi
}

echo "Building $IMAGE_NAME:$IMAGE_TAG"
docker build --no-cache -t $IMAGE_NAME .

echo "Tag $IMAGE_NAME for publishing
"
#If GCR is not set, use docker hub. Do note that you need to be signed in to a Docker Hub account
#
# docker login --username=yourhubusername --email=youremail@enonic.com
#
if [[ -z "$DOCKER_REGISTRY" ]]; then
  echo "Empty $DOCKER_REGISTRY, using Docker Hub as registry"
  docker tag $IMAGE_NAME $IMAGE_NAME:$IMAGE_TAG
  docker push enonic/xp:$IMAGE_TAG
else
  echo "Publishing $IMAGE_NAME:$IMAGE_TAG to $DOCKER_REGISTRY"
  docker tag $IMAGE_NAME $DOCKER_REGISTRY/$GCR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
  docker push $DOCKER_REGISTRY/$GCR_PROJECT/$IMAGE_NAME:$IMAGE_TAG
fi

checkReturn $? "push failed"
