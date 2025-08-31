FROM node:22-alpine

# CodeBuild-compatible setup with essential tools
ENV NODE_OPTIONS="--max-old-space-size=512"

# Install essential packages including tools for package management
RUN apk add --no-cache \
  bash \
  curl \
  wget \
  unzip \
  zip \
  aws-cli \
  git \
  jq \
  python3 \
  py3-pip && \
  rm -rf /var/cache/apk/*

# Install pnpm
RUN npm install -g --no-audit --no-fund pnpm && \
  npm cache clean --force

# Install Terraform
ARG TERRAFORM_VERSION=1.13.1
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/') && \
  wget -q -O /tmp/terraform.zip \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
  unzip -q /tmp/terraform.zip -d /usr/local/bin && \
  rm /tmp/terraform.zip

WORKDIR /workspace

# No custom entrypoint - CodeBuild compatible
