# This is a make file to test out multi-arch docker builds. This has only been tested on linux!

BUILD_PLATFORMS:=linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/arm/v7

.DEFAULT_GOAL:= help
.PHONY:="docker-builder-prepare docker-builder-create docker-build-test help"

docker-builder-prepare: ## Prepare multi arch builds. This needs to be done every time you reboot your machine!
	docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

docker-builder-create: ## Create a new builder. This only needs to be done once!
	docker buildx create --name ${BUILDER_NAME}
	docker buildx use ${BUILDER_NAME}
	docker buildx inspect --bootstrap

docker-builder-test: ##
	docker buildx build \
		--build-arg build_date=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
		--build-arg build_base_image=$(shell cat .env | grep -oP '(?<=BASE_IMAGE=).*') \
		--build-arg build_distro_version=$(shell cat .env | grep -oP '(?<=XP_VERSION=).*') \
		--platform ${BUILD_PLATFORMS} \
		-t xp-multiarch-test \
		.

help: ## Show target descriptions.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'