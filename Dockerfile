FROM node:22-alpine

# CodeBuild environment variables for memory optimization
ENV NODE_OPTIONS="--max-old-space-size=1024" \
  NPM_CONFIG_FUND=false \
  NPM_CONFIG_AUDIT=false \
  NPM_CONFIG_PROGRESS=false \
  NPM_CONFIG_LOGLEVEL=warn \
  PYTHONUNBUFFERED=1

# Install system packages
RUN apk update && apk add --no-cache \
  python3 \
  py3-pip \
  ca-certificates \
  openssl \
  bash \
  curl \
  jq \
  git \
  zip \
  unzip \
  wget \
  aws-cli && \
  rm -rf /var/cache/apk/* /tmp/*

# Install Node.js tools
RUN npm install -g --no-audit --no-fund pnpm && \
  npm cache clean --force && \
  rm -rf /root/.npm

# Install Terraform
ARG TERRAFORM_VERSION=1.13.1
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/') && \
  wget -q -O terraform.zip \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" && \
  unzip -q terraform.zip -d /usr/local/bin && \
  rm terraform.zip && \
  chmod +x /usr/local/bin/terraform

# Configure AWS CLI
RUN aws configure set preview.cloudfront true

# Create workspace
WORKDIR /workspace

# Labels
LABEL maintainer="jch254" \
  description="CodeBuild-optimized Docker image for Node.js/Terraform/AWS" \
  node.version="22" \
  terraform.version="${TERRAFORM_VERSION}"

# Simple entrypoint for CodeBuild compatibility
COPY entrypoint-simple.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use bash directly as entrypoint - CodeBuild expects this
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
