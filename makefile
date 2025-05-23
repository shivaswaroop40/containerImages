# Variables
DOCKER_BUILDX = docker buildx build
COSIGN = cosign
TRIVY = trivy
GHCR = ghcr.io
IMAGE_NAME = containerimages
TAG ?= $(shell git rev-parse --short HEAD)
PLATFORMS ?= linux/amd64,linux/arm64
COSIGN_PRIVATE_KEY ?= $(error COSIGN_PRIVATE_KEY is not set)
COSIGN_PUBLIC_KEY ?= $(error COSIGN_PUBLIC_KEY is not set)
KUBECTL = kubectl
ENVSUBST = envsubst
POLICY_DIR = policies

# Image names
SIGNED_IMAGE = $(GHCR)/shivaswaroop40/$(IMAGE_NAME)/signed
UNSIGNED_IMAGE = $(GHCR)/shivaswaroop40/$(IMAGE_NAME)/unsigned

# Help
help:
	@echo "Available targets:"
	@echo "  all              - Build, push, scan, and sign both images"
	@echo "  build-signed     - Build signed image"
	@echo "  build-unsigned   - Build unsigned image"
	@echo "  push-signed      - Push signed image"
	@echo "  push-unsigned    - Push unsigned image"
	@echo "  scan-signed      - Scan signed image"
	@echo "  scan-unsigned    - Scan unsigned image"
	@echo "  sign             - Sign the image"
	@echo "  verify           - Verify the image signature"
	@echo "  deploy-signed    - Deploy signed pod (use: make deploy-signed TAG=<sha>)"
	@echo "  deploy-unsigned  - Deploy unsigned pod (use: make deploy-unsigned TAG=<sha>)"
	@echo "  clean            - Clean up images"
	@echo "  get-latest-sha   - Get the latest image SHA from registry"
	@echo "  policy-create    - Create cluster policy"
	@echo "  policy-verify    - Verify cluster policy"
	@echo "  policy-cleanup   - Remove cluster policy"

# Get latest SHA from registry
get-latest-sha:
	@echo "🔍 Fetching latest image SHA..."
	@echo "Latest SHA for signed image:"
	@docker manifest inspect $(SIGNED_IMAGE):latest 2>/dev/null | grep -o '"digest":"sha256:[^"]*"' | head -n1 | cut -d'"' -f4 || echo "No signed image found"
	@echo "Latest SHA for unsigned image:"
	@docker manifest inspect $(UNSIGNED_IMAGE):latest 2>/dev/null | grep -o '"digest":"sha256:[^"]*"' | head -n1 | cut -d'"' -f4 || echo "No unsigned image found"

# Build targets
build-signed:
	@echo "🔨 Building signed image..."
	@echo "Using tag: $(TAG)"
	$(DOCKER_BUILDX) --platform $(PLATFORMS) -t $(SIGNED_IMAGE):$(TAG) .

build-unsigned:
	@echo "🔨 Building unsigned image..."
	@echo "Using tag: $(TAG)"
	$(DOCKER_BUILDX) --platform $(PLATFORMS) -t $(UNSIGNED_IMAGE):$(TAG) .

# Push targets
push-signed:
	@echo "⬆️ Pushing signed image..."
	@echo "Pushing with tag: $(TAG)"
	docker push $(SIGNED_IMAGE):$(TAG)

push-unsigned:
	@echo "⬆️ Pushing unsigned image..."
	@echo "Pushing with tag: $(TAG)"
	docker push $(UNSIGNED_IMAGE):$(TAG)

# Scan targets
scan-signed:
	@echo "🔍 Scanning signed image..."
	@echo "Scanning image with tag: $(TAG)"
	$(TRIVY) image --severity MEDIUM,HIGH,CRITICAL $(SIGNED_IMAGE):$(TAG)

scan-unsigned:
	@echo "🔍 Scanning unsigned image..."
	@echo "Scanning image with tag: $(TAG)"
	$(TRIVY) image --severity MEDIUM,HIGH,CRITICAL $(UNSIGNED_IMAGE):$(TAG)

# Signing targets
sign:
	@echo "🔐 Signing image..."
	@echo "Signing image with tag: $(TAG)"
	$(COSIGN) sign --key $(COSIGN_PRIVATE_KEY) $(SIGNED_IMAGE):$(TAG)

verify:
	@echo "✅ Verifying image signature..."
	@echo "Verifying image with tag: $(TAG)"
	$(COSIGN) verify --key $(COSIGN_PUBLIC_KEY) $(SIGNED_IMAGE):$(TAG)

# Deployment targets
deploy-signed:
	@echo "🚀 Deploying signed pod..."
	@echo "Using image tag: $(TAG)"
	@if [ -z "$(TAG)" ]; then \
		echo "Error: TAG is not set. Please run: make deploy-signed TAG=<sha>"; \
		exit 1; \
	fi
	IMAGE_SHA=$(TAG) $(ENVSUBST) < signed-app.yaml | $(KUBECTL) apply -f -

deploy-unsigned:
	@echo "🚀 Deploying unsigned pod..."
	@echo "Using image tag: $(TAG)"
	@if [ -z "$(TAG)" ]; then \
		echo "Error: TAG is not set. Please run: make deploy-unsigned TAG=<sha>"; \
		exit 1; \
	fi
	IMAGE_SHA=$(TAG) $(ENVSUBST) < unsigned-app.yaml | $(KUBECTL) apply -f -

# Policy targets
policy-create:
	@echo "📝 Creating cluster policy..."
	@if [ ! -d "$(POLICY_DIR)" ]; then \
		mkdir -p $(POLICY_DIR); \
	fi
	@echo "🔍 Checking if Kyverno is installed..."
	@if ! $(KUBECTL) get ns kyverno >/dev/null 2>&1; then \
		echo "❌ Kyverno namespace not found. Please install Kyverno first."; \
		exit 1; \
	fi
	@echo "📄 Applying cluster policy..."
	$(KUBECTL) apply -f cluster-policy.yaml
	@echo "✅ Cluster policy created successfully"

policy-verify:
	@echo "🔍 Verifying cluster policy..."
	@if ! $(KUBECTL) get clusterpolicy check-image >/dev/null 2>&1; then \
		echo "❌ Cluster policy not found"; \
		exit 1; \
	fi
	@echo "📊 Policy status:"
	$(KUBECTL) get clusterpolicy check-image -o yaml | grep -A 5 "status:"
	@echo "✅ Cluster policy verification completed"

policy-cleanup:
	@echo "🧹 Cleaning up cluster policy..."
	$(KUBECTL) delete -f cluster-policy.yaml || true
	@echo "✅ Cluster policy cleanup completed"

# Generate keys
generate-keys:
	@echo "🔑 Generating Cosign key pair..."
	$(COSIGN) generate-key-pair

# Cleanup
clean:
	@echo "🧹 Cleaning up images..."
	kubectl delete $(SIGNED_IMAGE):$(TAG) || true
	kubectl delete $(UNSIGNED_IMAGE):$(TAG) || true
	docker rmi $(SIGNED_IMAGE):$(TAG) || true
	docker rmi $(UNSIGNED_IMAGE):$(TAG) || true

# Default target
all: build-signed build-unsigned push-signed push-unsigned scan-signed scan-unsigned sign verify

.PHONY: all help build-signed build-unsigned push-signed push-unsigned scan-signed scan-unsigned sign verify deploy-signed deploy-unsigned generate-keys clean get-latest-sha policy-create policy-verify policy-cleanup