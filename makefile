# Variables
DOCKER_BUILDX = docker buildx build
COSIGN = cosign
TRIVY = trivy
GHCR = ghcr.io
IMAGE_NAME = containerimages
TAG ?= sha-$(shell git rev-parse --short HEAD)
PLATFORMS ?= linux/amd64,linux/arm64
KUBECTL = kubectl
ENVSUBST = envsubst

# Keyless verification: the workflow identity that is allowed to sign.
CERT_IDENTITY_REGEXP ?= ^https://github.com/shivaswaroop40/containerImages/.github/workflows/build.yaml@
CERT_OIDC_ISSUER ?= https://token.actions.githubusercontent.com

# Image names
SIGNED_IMAGE = $(GHCR)/shivaswaroop40/$(IMAGE_NAME)/signed
UNSIGNED_IMAGE = $(GHCR)/shivaswaroop40/$(IMAGE_NAME)/unsigned

# Help
help:
	@echo "Available targets:"
	@echo "  all              - Build, push, scan, sign, and verify both images"
	@echo "  build-signed     - Build and push the signed image (multi-arch)"
	@echo "  build-unsigned   - Build and push the unsigned image (multi-arch)"
	@echo "  scan-signed      - Scan signed image with Trivy"
	@echo "  scan-unsigned    - Scan unsigned image with Trivy"
	@echo "  sign             - Sign the image (keyless; opens a browser for OIDC)"
	@echo "  verify           - Verify the image signature (keyless)"
	@echo "  deploy-signed    - Deploy signed pod (use: make deploy-signed TAG=sha-<sha>)"
	@echo "  deploy-unsigned  - Deploy unsigned pod (use: make deploy-unsigned TAG=sha-<sha>)"
	@echo "  get-digest       - Print the manifest digest for the current TAG"
	@echo "  clean            - Delete demo pods and local images"
	@echo "  policy-create    - Apply the Kyverno cluster policy"
	@echo "  policy-verify    - Check the cluster policy status"
	@echo "  policy-cleanup   - Remove the cluster policy"

# Print the digest for the current TAG (sign and verify by digest, not tag)
get-digest:
	@echo "Signed image digest for $(TAG):"
	@docker buildx imagetools inspect $(SIGNED_IMAGE):$(TAG) --format '{{json .Manifest.Digest}}' 2>/dev/null || echo "No signed image found for tag $(TAG)"
	@echo "Unsigned image digest for $(TAG):"
	@docker buildx imagetools inspect $(UNSIGNED_IMAGE):$(TAG) --format '{{json .Manifest.Digest}}' 2>/dev/null || echo "No unsigned image found for tag $(TAG)"

# Build targets. Multi-arch images cannot be loaded into the local Docker
# daemon, so build and push are one step.
build-signed:
	@echo "Building and pushing signed image with tag: $(TAG)"
	$(DOCKER_BUILDX) --platform $(PLATFORMS) -t $(SIGNED_IMAGE):$(TAG) --push .

build-unsigned:
	@echo "Building and pushing unsigned image with tag: $(TAG)"
	$(DOCKER_BUILDX) --platform $(PLATFORMS) -t $(UNSIGNED_IMAGE):$(TAG) --push .

# Scan targets
scan-signed:
	@echo "Scanning signed image with tag: $(TAG)"
	$(TRIVY) image --severity MEDIUM,HIGH,CRITICAL $(SIGNED_IMAGE):$(TAG)

scan-unsigned:
	@echo "Scanning unsigned image with tag: $(TAG)"
	$(TRIVY) image --severity MEDIUM,HIGH,CRITICAL $(UNSIGNED_IMAGE):$(TAG)

# Signing targets. Keyless: cosign opens a browser to get a short-lived
# certificate from Fulcio and records it in Rekor. Signs the digest that the
# tag currently resolves to.
sign:
	@echo "Signing image (keyless) for tag: $(TAG)"
	$(COSIGN) sign --yes $(SIGNED_IMAGE):$(TAG)

verify:
	@echo "Verifying image signature (keyless) for tag: $(TAG)"
	$(COSIGN) verify \
		--certificate-identity-regexp "$(CERT_IDENTITY_REGEXP)" \
		--certificate-oidc-issuer "$(CERT_OIDC_ISSUER)" \
		$(SIGNED_IMAGE):$(TAG)

# Deployment targets. The manifests reference ${IMAGE_SHA}, substituted here.
deploy-signed:
	@echo "Deploying signed pod with tag: $(TAG)"
	IMAGE_SHA=$(TAG) $(ENVSUBST) < signed-app.yaml | $(KUBECTL) apply -f -

deploy-unsigned:
	@echo "Deploying unsigned pod with tag: $(TAG)"
	IMAGE_SHA=$(TAG) $(ENVSUBST) < unsigned-app.yaml | $(KUBECTL) apply -f -

# Policy targets
policy-create:
	@echo "Checking that Kyverno is installed..."
	@if ! $(KUBECTL) get ns kyverno >/dev/null 2>&1; then \
		echo "Kyverno namespace not found. Install Kyverno first."; \
		exit 1; \
	fi
	$(KUBECTL) apply -f cluster-policy.yaml

policy-verify:
	@if ! $(KUBECTL) get clusterpolicy check-image >/dev/null 2>&1; then \
		echo "Cluster policy not found"; \
		exit 1; \
	fi
	$(KUBECTL) get clusterpolicy check-image -o yaml | grep -A 5 "status:"

policy-cleanup:
	$(KUBECTL) delete -f cluster-policy.yaml || true

# Cleanup
clean:
	@echo "Deleting demo pods and local images..."
	$(KUBECTL) delete pod signed-image-pod --ignore-not-found
	$(KUBECTL) delete pod unsigned-image-pod --ignore-not-found
	docker rmi $(SIGNED_IMAGE):$(TAG) 2>/dev/null || true
	docker rmi $(UNSIGNED_IMAGE):$(TAG) 2>/dev/null || true

# Default target
all: build-signed build-unsigned scan-signed scan-unsigned sign verify

.PHONY: all help build-signed build-unsigned scan-signed scan-unsigned sign verify deploy-signed deploy-unsigned clean get-digest policy-create policy-verify policy-cleanup
