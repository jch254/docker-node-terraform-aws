# docker-node-terraform-aws

[![Docker Hub](https://img.shields.io/docker/pulls/jch254/docker-node-terraform-aws)](https://hub.docker.com/r/jch254/docker-node-terraform-aws) [![Docker Image Size](https://img.shields.io/docker/image-size/jch254/docker-node-terraform-aws/22.x)](https://hub.docker.com/r/jch254/docker-node-terraform-aws) [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Container image providing a consistent build & deployment toolchain for Node.js projects targeting AWS infrastructure with Terraform. Designed for CI systems like [Bitbucket Pipelines](https://bitbucket.org/product/features/pipelines) and [AWS CodeBuild](https://aws.amazon.com/codebuild).

## Included Tooling (see `Dockerfile` for full list)

| Tool | Version (default) | Notes |
|------|-------------------|-------|
| Node.js | 22 (alpine base) | Other major versions via branches/tags (below) |
| Terraform | 1.13.1 (override via build arg) | `ARG TERRAFORM_VERSION` supported |
| AWS CLI v2 | Latest available in Alpine repo | CloudFront preview enabled |
| Python 3 + pip | From Alpine | For auxiliary scripts / AWS CLI deps |
| npm | Built-in with Node | Default Node.js package manager |
| Yarn | Alpine package | Alternative Node package manager |
| pnpm | Latest via npm | Fast, disk space efficient package manager |
| jq / curl / git / zip / unzip / bash / wget / less / groff / openssl | System utilities | Common scripting + packaging needs |

Healthcheck validates `node`, `terraform`, and `aws` availability.

## Supported Node Base Versions / Branch Mapping

Each maintained major Node line has a matching branch + Docker tag. Current upstream LTS / alias mapping (as of 2025-08) for reference:

| Branch | Node Major | LTS Codename (if applicable) | Upstream alias examples | Example Pull |
|--------|-----------|------------------------------|-------------------------|--------------|
| `12.x` | 12 | Erbium (EOL) | lts/erbium | `docker pull jch254/docker-node-terraform-aws:12.x` |
| `14.x` | 14 | Fermium (EOL) | lts/fermium | `docker pull jch254/docker-node-terraform-aws:14.x` |
| `16.x` | 16 | Gallium (EOL) | lts/gallium | `docker pull jch254/docker-node-terraform-aws:16.x` |
| `18.x` | 18 | Hydrogen (Maintenance) | lts/hydrogen | `docker pull jch254/docker-node-terraform-aws:18.x` |
| `20.x` | 20 | Iron (Active LTS) | lts/iron | `docker pull jch254/docker-node-terraform-aws:20.x` |
| `22.x` | 22 | Jod (Current LTS) - **Current** | lts/jod | `docker pull jch254/docker-node-terraform-aws:22.x` |
| `24.x` | 24 | (Current Latest / Stable) | stable, node | `docker pull jch254/docker-node-terraform-aws:24.x` |

Notes:

* `stable` / `node` upstream presently resolve to v24.7.0.
* Historical LTS codenames listed for clarity; some are End Of Life (EOL) and provided only for reproducibility.
* Prefer a pinned major tag (e.g. `22.x`, `24.x`) or digest for deterministic CI builds.

`latest` generally tracks the highest actively maintained major (currently Node 22). Pin a major tag (e.g. `22.x`) for stability in CI.

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

You can substitute any published Terraform version; architecture (amd64 / arm64) is auto-detected.

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

Configure the project to use the public image `jch254/docker-node-terraform-aws:22.x` (or another tag) as a custom image.

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

## Healthcheck

The image includes a Docker `HEALTHCHECK` executing lightweight version commands. In high-frequency short-lived CI containers you can safely ignore it; for long-running ephemeral build runners it provides a basic sanity signal.

## Updating / Maintenance

* Base updates: periodically rebuild when upstream `node:<major>-alpine` publishes security patches.
* Terraform: bump default by updating `ARG TERRAFORM_VERSION` in `Dockerfile` (and rebuild / retag).
* Tag discipline: prefer immutable CI references (e.g. digest pin) if supply chain repeatability is critical.

## Example Project

See [serverless-node-dynamodb-ui](https://github.com/jch254/serverless-node-dynamodb-ui) demonstrating usage in a Serverless + Terraform workflow.

## Contributing

1. Fork & branch (`feat/...` or `chore/...`).
2. Make changes; keep layers minimal.
3. Build & smoke test:

```bash
docker build -t test-image . && docker run --rm test-image "terraform version"
```

1. Open PR describing rationale (tool additions, version bumps, optimizations).

## Issues / Support

Please open a GitHub issue with:

* Image tag / digest
* CI environment (Bitbucket Pipelines, CodeBuild, local, etc.)
* Repro steps & exact error output

## Security

No root password, minimal additional packages. For stricter environments you may:

* Add vulnerability scanning (e.g. `docker scout cves` or Trivy) in CI.
* Pin package versions explicitly (currently using rolling Alpine repo versions for utilities).

## License

Released under the [MIT License](LICENSE). By contributing you agree that your contributions are licensed under the same MIT license.

---
Pull requests to improve size, security posture, or docs are welcome.
