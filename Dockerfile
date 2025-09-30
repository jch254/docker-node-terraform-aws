FROM public.ecr.aws/docker/library/node:18-alpine

# Install system packages and clean up in single layer
RUN apk add --no-cache \
  python3 \
  py3-pip \
  ca-certificates \
  openssl \
  groff \
  less \
  bash \
  curl \
  jq \
  git \
  zip \
  unzip \
  wget \
  aws-cli \
  yarn && \
  # Install pnpm globally
  npm install -g pnpm && \
  # Clean up package cache
  rm -rf /var/cache/apk/* && \
  # Configure AWS CLI
  aws configure set preview.cloudfront true

# Define versions as build arguments for flexibility
ARG TERRAFORM_VERSION=1.13.1

# Install Terraform with architecture detection
RUN TERRAFORM_ARCH="$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')" && \
  wget -O terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" && \
  unzip terraform.zip -d /usr/local/bin && \
  rm -f terraform.zip && \
  # Verify installation
  terraform version

# Add labels for better maintainability
LABEL maintainer="jch254" \
  description="Docker image for Node.js/Terraform/AWS development" \
  node.version="18" \
  terraform.version="${TERRAFORM_VERSION}"

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node --version && terraform version && aws --version || exit 1

ENTRYPOINT ["/bin/bash", "-c"]