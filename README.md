# docker-node-terraform-aws

[![Docker Hub](https://img.shields.io/docker/pulls/jch254/docker-node-terraform-aws)](https://hub.docker.com/r/jch254/docker-node-terraform-aws) [![Docker Image Size](https://img.shields.io/docker/image-size/jch254/docker-node-terraform-aws/latest)](https://hub.docker.com/r/jch254/docker-node-terraform-aws) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Container image providing a consistent build & deployment toolchain for Node.js projects targeting AWS infrastructure with Terraform. Designed for CI systems like [Bitbucket Pipelines](https://bitbucket.org/product/features/pipelines) and [AWS CodeBuild](https://aws.amazon.com/codebuild).

Focused goals:

* Stable, reproducible CI environment (Node + Terraform + AWS CLI v2)
* Lean Alpine base (fast pulls) while retaining essential utilities
* Straightforward override of Terraform version & deterministic tagging
* Proven to work in CodeBuild (avoid SINGLE_BUILD_CONTAINER_DEAD via correct architecture)

## Included Tooling (see `Dockerfile` for authoritative list)

| Tool | Version / Source | Notes |
|------|------------------|-------|
| Node.js | 22 (node:22-alpine) | Use tag `22.x` (pin by digest for immutability) |
| Terraform | 1.13.1 (default) | Override with `--build-arg TERRAFORM_VERSION=...` |
| AWS CLI v2 | Alpine repo | Installed via `apk add aws-cli` |
| Python 3 + pip | Alpine repo | For helper scripts / AWS tooling |
| npm | Bundled with Node | Core JS package manager |
| pnpm | Latest (global install) | Fast dependency installs |
| jq / curl / git / zip / unzip / bash / wget | Utilities | Common scripting + archive tasks |

Not included by default: Yarn (available via Corepack: `corepack enable yarn`), extra pagers (less, groff), OpenSSL headers, build toolchains (add as needed).

No Docker `HEALTHCHECK` is defined to keep startup overhead minimal. CI systems typically exit on command failure; a healthcheck is seldom necessary. Add one if you run long‑lived build agents.

## Tags & Versioning

Primary maintained tag in this repo: `22.x` (Node 22). The `latest` tag currently points to the same major (verify with `docker pull jch254/docker-node-terraform-aws:latest` then inspect digest). Older / newer majors may exist in other branches or historical tags; pin by digest for reproducibility:

```bash
docker pull jch254/docker-node-terraform-aws:22.x@sha256:<digest>
```

Why digest pinning?

* Guarantees identical toolchain across parallel / future CI runs
* Enables staged rollouts (update tag, keep old digest in rollback config)

To discover the digest after pulling:

```bash
docker inspect --format='{{index .RepoDigests 0}}' jch254/docker-node-terraform-aws:22.x
```

## Quick Start

Pull and run an interactive shell:

```bash
docker run -it --rm jch254/docker-node-terraform-aws:22.x bash
```

Check installed versions:

```bash
docker run --rm jch254/docker-node-terraform-aws:22.x "node --version && terraform version && aws --version"
```

## Overriding Terraform Version (local build)

```bash
docker build --build-arg TERRAFORM_VERSION=1.13.1 -t my/ci-image:tf-1.13.1 .
```

You can substitute any published Terraform version; architecture (amd64 / arm64) is auto-detected during build.

For CodeBuild (currently x86_64 / amd64), ensure you build / push an amd64 image (or multi-arch) and explicitly pull it locally if you're on Apple Silicon:

```bash
docker build --platform linux/amd64 -t jch254/docker-node-terraform-aws:22.x .
```

## Bitbucket Pipelines Example

```yaml
image: jch254/docker-node-terraform-aws:22.x

pipelines:
	default:
		- step:
				name: Terraform Plan
				script:
					- node --version
					- terraform -chdir=infrastructure init
					- terraform -chdir=infrastructure plan -out tfplan
```

## AWS CodeBuild `buildspec.yml` Example

```yaml
version: 0.2
phases:
	install:
		runtime-versions: {}
	pre_build:
		commands:
			- node --version
			- terraform -chdir=infrastructure init
	build:
		commands:
			- terraform -chdir=infrastructure apply -auto-approve
```

Configure the project to use the public image `jch254/docker-node-terraform-aws:22.x` (or a digest‑pinned variant) as a custom image.

Additional samples:

* `buildspec-example.yml` – fuller workflow with conditional apply & caching
* `buildspec-minimal.yml` – lean template useful for diagnosing environment problems

## Caching Tips

* Terraform plugin/cache directory: mount a volume to persist between runs:

```bash
docker run -v "$PWD":/workspace -v tf_plugins:/root/.terraform.d/plugin-cache ...
```

Then add to `~/.terraformrc` (in your repo) if you want explicit plugin cache control:

```hcl
plugin_cache_dir = "/root/.terraform.d/plugin-cache"
```

* Node/Yarn dependencies: in CI, leverage built-in caching (Bitbucket `caches: node`) or mount a volume locally.

## Architecture Notes

AWS CodeBuild standard environments presently require `linux/amd64`. If you build this image on an ARM (e.g. Apple M-series) and push without a multi‑arch manifest, CodeBuild may pull an incompatible layer or fail early with opaque errors (e.g. `SINGLE_BUILD_CONTAINER_DEAD`). Always build with `--platform linux/amd64` (or use `docker buildx build --platform linux/amd64,linux/arm64 ...` for multi‑arch) before pushing.

## Updating / Maintenance

* Base updates: periodically rebuild when upstream `node:<major>-alpine` publishes security patches.
* Terraform: bump default by updating `ARG TERRAFORM_VERSION` in `Dockerfile` (and rebuild / retag).
* Tag discipline: prefer immutable CI references (e.g. digest pin) if supply chain repeatability is critical.

## IAM & Terraform Troubleshooting

Common Terraform plan/apply AWS errors in CI & resolutions:

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `AccessDenied: ec2:DescribeVpcAttribute` | Missing EC2 read perms on build role | Add `ec2:Describe*` minimal set needed by your data sources |
| `UnauthorizedOperation: logs:ListTagsForResource` | CloudWatch Logs tag listing blocked | Grant `logs:ListTagsForResource` (or broader read if acceptable) |
| `AccessDenied: ecr:DescribeRepositories` | Build role lacks ECR read | Add `ecr:DescribeRepositories` or scoped resource ARNs |

Least‑privilege tip: run `terraform plan` with `TF_LOG=DEBUG` (temporarily) to enumerate denied actions, aggregate, then tighten to wildcard groups (e.g. `ec2:Describe*`) where appropriate.

Environment vars helpful in CI:

```bash
export TF_IN_AUTOMATION=true
export AWS_PAGER=""
export NODE_OPTIONS="--max-old-space-size=512"  # adjust for instance size
```

## Building Docker Images Inside CodeBuild

If you see:

```text
ERROR: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

The build container cannot reach a Docker daemon. Fix options:

### 1. (Recommended) Enable Privileged Mode

In the CodeBuild project settings enable "Privileged" (or in IaC `privilegedMode: true`). This mounts the host Docker daemon socket inside your build so `docker build` works.

Minimum IAM permissions added to the CodeBuild role when pushing to ECR (adjust resource ARNs):

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{ "Effect": "Allow", "Action": ["ecr:GetAuthorizationToken"], "Resource": "*" },
		{ "Effect": "Allow", "Action": [
				"ecr:BatchCheckLayerAvailability",
				"ecr:CompleteLayerUpload",
				"ecr:DescribeRepositories",
				"ecr:BatchGetImage",
				"ecr:InitiateLayerUpload",
				"ecr:PutImage",
				"ecr:UploadLayerPart"
			], "Resource": "arn:aws:ecr:<region>:<account>:repository/<repo-name>" }
	]
}
```

Typical buildspec excerpt:

```yaml
phases:
	pre_build:
		commands:
			- aws --version
			- aws ecr get-login-password | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
	build:
		commands:
			- docker build --platform linux/amd64 -t "$IMAGE_REPO_NAME:$IMAGE_TAG" .
			- docker tag "$IMAGE_REPO_NAME:$IMAGE_TAG" "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG"
	post_build:
		commands:
			- docker push "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG"
```

Add a quick guard early (helps fail fast if privileged not enabled):

```bash
test -S /var/run/docker.sock || { echo "Docker socket missing (privileged mode off)"; exit 1; }
```

### 2. Use Kaniko (No Privileged Mode)

If you cannot enable privileged mode, swap Docker daemon usage for [Kaniko]. Example (add to this image at runtime):

```bash
curl -sSL https://github.com/GoogleContainerTools/kaniko/releases/latest/download/executor-linux-amd64 -o /usr/local/bin/kaniko && chmod +x /usr/local/bin/kaniko
kaniko --destination "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG" --context . --build-arg TERRAFORM_VERSION=1.13.1
```

Supply `/kaniko/.docker/config.json` with ECR auth (or export `AWS_*` env vars—Kaniko supports the SDK creds).

### 3. Use AWS CodeBuild Managed Builds / CodePipeline

If you only need to run Terraform (and not build container images) remove `docker build` lines entirely—this image already includes your toolchain.

### 4. Install Docker CLI (if missing)

This image does not ship with the Docker CLI. If you enabled privileged mode but receive `docker: not found`, layer it:

```bash
apk add --no-cache docker-cli
```

Keep this in a separate layer (or derive a child image) rather than bloating the base if most consumers do not need image builds.

### Quick Decision Matrix

| Need | Best Option |
|------|-------------|
| Build & push images (have permission) | Privileged mode + Docker CLI |
| Build images without privileged mode | Kaniko (or BuildKit rootless) |
| Only Terraform + Node builds | Drop Docker steps |
| Multi-arch build inside CI | Buildx (privileged) or external pipeline |

If multi‑arch is required, add Buildx:

```bash
docker buildx create --use --name ci-builder
docker buildx build --platform linux/amd64,linux/arm64 -t "$IMAGE" --push .
```

Ensure QEMU emulators are registered (standard CodeBuild privileged hosts usually have them, else install `qemu-user-static`).

## Contributing

1. Fork & branch (`feat/...` or `chore/...`).
2. Make changes; keep layers minimal (group `apk add` lines, remove caches).
3. Build & smoke test (force amd64 if on ARM host):

```bash
docker build -t test-image . && docker run --rm test-image "terraform version"
```

1. Open PR describing rationale (tool additions, version bumps, optimizations, size/security impact).

## Issues / Support

Please open a GitHub issue with:

* Image tag / digest
* CI environment (Bitbucket Pipelines, CodeBuild, local, etc.)
* Repro steps & exact error output

## Security

Baseline hardening considerations (opt-in):

* Run as non-root (add user + `USER` directive) if build steps permit.
* Add vulnerability scanning (e.g. Trivy, Grype, or `docker scout cves`) in CI.
* Pin Alpine repository snapshot (e.g. use a specific minor tag) for utility determinism.
* Consider digest pinning of Terraform zip (verify SHA256) for supply chain integrity.
* Trim unused package managers (remove pnpm if not needed) to reduce surface.

## License

Released under the [MIT License](LICENSE). By contributing you agree that your contributions are licensed under the same MIT license.

---
Pull requests to improve size, security posture, or docs are welcome.