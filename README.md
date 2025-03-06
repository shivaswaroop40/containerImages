# GitHub Actions: Build, Scan, and Sign Docker Images

This workflow automates the **building**, **scanning**, and **signing** of container images using **GitHub Actions**.

## 📌 Overview
1. **Build and Push Unsigned Image**: Creates a Docker image and pushes it to GHCR.
2. **Build and Push Signed Image**: Builds a signed container image using Cosign.
3. **Scan Image for Vulnerabilities**: Uses Trivy to detect security issues.
4. **Sign and Verify Image**: Ensures authenticity with Cosign.

---

## 🚀 Stages Explained

### 🔨 Build and Push Unsigned Image
- Uses **Docker Buildx** to build a multi-platform image.
- Pushes an **unsigned** image to GitHub Container Registry (GHCR).

#### **Key Workflow Steps:**
1. Checkout repository code.
2. Set up **Docker Buildx**.
3. Authenticate to **GHCR**.
4. Generate metadata (tags) for the image.
5. Build and push the **unsigned** image.

---

### 🔏 Build and Push Signed Image
- Builds and signs the image using **Cosign**.
- Supports **linux/amd64** and **linux/arm64** platforms.
- Stores the signed image in **GHCR**.

#### **Key Workflow Steps:**
1. Install **Cosign** for signing images.
2. Enable **QEMU** for multi-platform support.
3. Set up **Docker Buildx**.
4. Authenticate to **GHCR**.
5. Generate metadata (tags) for the image.
6. Build and push the **signed** image.

---

### 🛡️ Scan Image for Vulnerabilities (Trivy)
- Uses [Aqua Security's Trivy](https://github.com/aquasecurity/trivy) to scan for vulnerabilities.
- Supports severity levels **MEDIUM, HIGH, CRITICAL**.
- Generates a Software Bill of Materials (SBOM) report.

#### **Key Workflow Steps:**
1. Authenticate using GitHub credentials.
2. Scan the **signed image**.
3. Upload the **SBOM report** as a GitHub artifact.

---

### 🔐 Sign and Verify Image (Cosign)
- Uses [Cosign](https://github.com/sigstore/cosign) to sign and verify the image.
- Ensures the container image is **trusted and secure** before deployment.

#### **Key Workflow Steps:**
1. **Sign the image** using `cosign sign`.
2. **Verify the signature** using `cosign verify`.

#### **Inputs & Secrets:**
| Name                | Description                                   |
|---------------------|----------------------------------------------|
| `COSIGN_PRIVATE_KEY` | Private key used for signing.               |
| `COSIGN_PASSWORD`    | Password to unlock the private key.         |
| `COSIGN_PUBLIC_KEY`  | Public key for verifying the signature.     |

---

## 📌 How to Use This Workflow
1. Ensure you have the required **secrets** set up in your GitHub repository:
   - `GITHUB_TOKEN`
   - `COSIGN_PRIVATE_KEY`
   - `COSIGN_PUBLIC_KEY`
   - `COSIGN_PASSWORD`
2. Push a Docker image to a private registry.
3. Trigger the GitHub Action.
4. View Trivy results under **GitHub Actions → Artifacts**.
5. Verify that the image is signed successfully.

---

## 🛠️ Troubleshooting
- **Build fails**: Ensure `GHCR` authentication is correctly configured.
- **Trivy scan issues**: Check if the correct image tag is used.
- **Cosign verification fails**: Verify that the correct **public key** is used.

For any issues, refer to:
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)

---

## 📢 Additional Notes
- This workflow supports **multi-platform builds**.
- Trivy can scan for **misconfigurations, secrets, and licenses**.
- Cosign integrates with **Sigstore** for keyless signing.

This workflow ensures that your container images are **secure, signed, and verifiable** before deployment. ✅

## Example Commands
### Verify Image Locally

Use Cosign to verify a signed image:

    cosign verify --key <path-to-public-key> ghcr.io/shivaswaroop40/containerimages/my-signed-image 

### Tools Used

- Docker Buildx • Advanced Docker builds with multi-platform support.

- Cosign • Sign and verify container images to enhance security.

- GHCR • GitHub-hosted container registry for Docker images.
Feedback and Contributions

- Trivy: Container Security Tool

We welcome your feedback and contributions!

- Open issues to suggest improvements or report problems.
- Submit pull requests to enhance the workflow.

### Link to my presentation: [CNCF](/CNCF.pdf)

Contact

Feel free to reach out for questions or collaboration opportunities!

Email: shivaswaroop40@gmail.com

LinkedIn: [Shiva Swaroop N K](https://www.linkedin.com/in/shivaswaroop-nittoor-krishnamurthy-67551a14b/)

Twitter: [Shiva Swaroop N K](https://x.com/shivu_2412)
