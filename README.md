# **Docker Image Build and Signing Workflow**

This repository contains a GitHub Actions workflow to:

1. Build and push Docker images to **GitHub Container Registry (GHCR)**.
2. Sign container images using **Cosign**.
3. Verify image signatures to ensure security.

---

## **Workflow Overview**

### **Trigger**

- Trigger manually via the `workflow_dispatch` event.

### **Jobs**

1. **Build Unsigned Image**: Builds and pushes unsigned container images.
2. **Build Signed Image**: Builds, signs, and pushes container images.

---

## **How to Use**

### **1. Setting Up Secrets**

Add the following secrets to your repository:

| Secret Name             | Description                                           |
|-------------------------|-------------------------------------------------------|
| `GITHUB_TOKEN`          | Auto-generated token for accessing GHCR.             |
| `COSIGN_PRIVATE_KEY`    | Private key for signing images with Cosign.          |
| `COSIGN_PUBLIC_KEY`     | Public key for verifying signatures.                 |
| `COSIGN_PASSWORD`       | Password for decrypting the private key.             |

---

### **2. Running the Workflow**

1. Navigate to the **Actions** tab in your GitHub repository.
2. Select **Build and Sign Docker Images**.
3. Click **Run workflow** to trigger the workflow.

---

## **Workflow Steps**

### **Build Unsigned Image**

- Checks out the code.
- Sets up Docker Buildx.
- Logs into GHCR.
- Generates metadata (tags and digest).
- Builds and pushes the unsigned image.
- Saves the image as an OCI tarball at `/tmp/output-unsigned.tar`.

### **Build Signed Image**

- Installs Cosign for signing images.
- Sets up Docker Buildx and QEMU for multi-platform builds.
- Logs into GHCR.
- Generates metadata (tags and digest).
- Builds and pushes the signed image.
- Signs the image using Cosign.
- Verifies the image signature with Cosign.

---

## **Outputs**

- **Unsigned Image**:
  - **Path**: `ghcr.io/shivaswaroop40/containerimages/my-unsigned-image`
  - **Tarball**: `/tmp/output-unsigned.tar`
- **Signed Image**:
  - **Path**: `ghcr.io/shivaswaroop40/containerimages/my-signed-image`
  - **Tarball**: `/tmp/output-signed.tar`

---

## **Example Commands**

### **Verify Image Locally**

Use Cosign to verify a signed image:

```bash
cosign verify --key <path-to-public-key> ghcr.io/shivaswaroop40/containerimages/my-signed-image
```

Tools Used

Docker Buildx
	•	Advanced Docker builds with multi-platform support.

Cosign
	•	Sign and verify container images to enhance security.

GHCR
	•	GitHub-hosted container registry for Docker images.

## Feedback and Contributions

We welcome your feedback and contributions!
- Open issues to suggest improvements or report problems.
- Submit pull requests to enhance the workflow.

Contact

Feel free to reach out for questions or collaboration opportunities!

Shivaswaroop Nittoor Krshnamurthy
- LinkedIn: Your Profile
- Twitter: Your Handle
