FROM node:22-alpine

# Set memory-friendly npm configuration
ENV NPM_CONFIG_FUND=false \
  NPM_CONFIG_AUDIT=false \
  NPM_CONFIG_PROGRESS=false \
  NPM_CONFIG_LOGLEVEL=warn

# Install system packages and tools in optimized stages
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
  yarn \
  aws-cli && \
  # Install pnpm with memory limits
  npm install -g --no-audit --no-fund --silent pnpm && \
  # Clean up caches to reduce image size
  rm -rf /var/cache/apk/* /root/.npm /tmp/* && \
  # Configure AWS CLI
  aws configure set preview.cloudfront true

# Define versions as build arguments for flexibility
ARG TERRAFORM_VERSION=1.13.1

# Install Terraform with memory-conscious approach
RUN TERRAFORM_ARCH="$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')" && \
  wget -q -O terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" && \
  unzip -q terraform.zip -d /usr/local/bin && \
  rm -f terraform.zip && \
  chmod +x /usr/local/bin/terraform && \
  # Verify installation without verbose output
  terraform version > /dev/null

# Add labels for better maintainability
LABEL maintainer="jch254" \
  description="Docker image for Node.js/Terraform/AWS development" \
  node.version="22" \
  terraform.version="${TERRAFORM_VERSION}"

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use optimized entrypoint for CodeBuild compatibility
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]