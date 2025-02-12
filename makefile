# Variables
DOCKER_BUILDX = docker buildx build
COSIGN = cosign
TRIVY = trivy
GHCR = ghcr.io
IMAGE_NAME = containerimages
TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64
COSIGN_PRIVATE_KEY ?= $(error COSIGN_PRIVATE_KEY is not set)
COSIGN_PUBLIC_KEY ?= $(error COSIGN_PUBLIC_KEY is not set)

# Targets
all: build push scan generate-keys sign-verify

build:
	$(DOCKER_BUILDX) --platform $(PLATFORMS) -t $(GHCR)/$(IMAGE_NAME):$(TAG) .

push:
	docker push $(GHCR)/$(IMAGE_NAME):$(TAG)

scan:
	$(TRIVY) image --severity MEDIUM,HIGH,CRITICAL $(GHCR)/$(IMAGE_NAME):$(TAG)

generate-keys:
	$(COSIGN) generate-key-pair

sign:
	$(COSIGN) sign --key $(COSIGN_PRIVATE_KEY) $(GHCR)/$(IMAGE_NAME):$(TAG)

sign-verify:
	$(COSIGN) verify --key $(COSIGN_PUBLIC_KEY) $(GHCR)/$(IMAGE_NAME):$(TAG)

clean:
	docker rmi $(GHCR)/$(IMAGE_NAME):$(TAG)