# containerImages

A container supply-chain pipeline you can copy: build, scan, sign, verify, and
then have the cluster refuse to run anything that skipped the process.

Two images get built from the same Dockerfile. One goes through the full
pipeline and comes out signed with an SBOM attached. The other is pushed as-is.
A Kyverno policy at admission lets the first one run and rejects the second.
That rejection is the whole demo.

I built this for my talk at the Stockholm Cloud Native meetup
([slides](https://github.com/shivaswaroop40/containerImages/releases/download/talk-slides/CNCF.pdf))
and kept using it afterwards.

## The pipeline

Every push to `main` runs [build.yaml](.github/workflows/build.yaml):

1. **Build** a multi-arch image (amd64 + arm64) with Buildx and push to GHCR,
   with BuildKit provenance set to `mode=max`.
2. **Scan** the pushed digest with Trivy. CRITICAL or HIGH findings fail the
   job, so a vulnerable image never gets a signature.
3. **Generate an SBOM** (CycloneDX) with Trivy and upload it as a workflow
   artifact.
4. **Sign the digest** with Cosign, keyless. GitHub's OIDC token gets exchanged
   for a short-lived Fulcio certificate, and the signature lands in the Rekor
   transparency log. No key secrets anywhere in the repo.
5. **Attest the SBOM** against the same digest, keyless again.
6. **Verify** both the signature and the attestation before the job goes green.

Two details carry most of the security value:

- Everything downstream of the build refers to the image by digest. Tags are
  mutable; a signature on a tag is a signature on whatever the tag points at
  today.
- Scanning happens before signing. The signature means "this image passed",
  and once something is in Rekor it is there forever.

## Enforcement

[cluster-policy.yaml](cluster-policy.yaml) is a Kyverno `ClusterPolicy` with
three rules:

- `verify-signature`: any Pod using an image from
  `ghcr.io/shivaswaroop40/containerimages/*` must carry a keyless signature
  from this repo's build workflow on `main`. Kyverno checks the Fulcio
  identity, so a signature from any other repo or workflow fails. It also
  rewrites the tag to the verified digest (`mutateDigest`).
- `verify-sbom-attestation`: the signed image must also carry a CycloneDX
  attestation from the same identity.
- `require-digest`: anything from this registry namespace still referenced by
  bare tag at validation time is rejected.

## Try it

You need a cluster with [Kyverno](https://kyverno.io/docs/installation/)
installed, plus a `ghcr-secret` image pull secret in the `kyverno` namespace.

```sh
make policy-create                  # apply the ClusterPolicy
make deploy-signed TAG=sha-<sha>    # admitted, tag mutated to digest
make deploy-unsigned TAG=sha-<sha>  # rejected by the policy
```

Grab a valid `<sha>` from the tags on the
[GHCR packages](https://github.com/shivaswaroop40?tab=packages&repo_name=containerImages),
or check digests with `make get-digest`.

Verifying an image locally takes one command and no keys:

```sh
cosign verify \
  --certificate-identity-regexp '^https://github.com/shivaswaroop40/containerImages/.github/workflows/build.yaml@' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/shivaswaroop40/containerimages/signed@sha256:<digest>
```

The [makefile](makefile) also has targets for local builds, scans, and keyless
signing (`make help` lists them). Local `make sign` opens a browser for the
OIDC flow and signs with your own identity, so images signed that way will not
pass the cluster policy. Good for experiments, not for the demo.

## Tools

- [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/), multi-arch builds
- [Cosign](https://docs.sigstore.dev/cosign/overview/) + [Sigstore](https://www.sigstore.dev/) (Fulcio, Rekor), keyless signing
- [Trivy](https://aquasecurity.github.io/trivy/), vulnerability scanning and SBOM generation
- [Kyverno](https://kyverno.io/), admission-time enforcement
- [GHCR](https://ghcr.io), the registry

Issues and PRs welcome.

## Contact

- Email: shivaswaroop40@gmail.com
- LinkedIn: [Shiva Swaroop N K](https://www.linkedin.com/in/shivaswaroop-nittoor-krishnamurthy-67551a14b/)
- X: [@podsandkapi](https://x.com/podsandkapi)

[MIT](LICENSE)
