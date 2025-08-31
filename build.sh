#!/bin/bash

# Build script for docker-node-terraform-aws with multi-architecture support
# This ensures the image works on both local development (ARM64) and CodeBuild (AMD64)

set -e

IMAGE_NAME="docker-node-terraform-aws"
TAG=${1:-"22.x"}

echo "Building Docker image for multiple architectures..."

# Build for AMD64 (CodeBuild)
echo "Building for AMD64 (CodeBuild/x86_64)..."
docker build --platform linux/amd64 -t ${IMAGE_NAME}:${TAG}-amd64 .

# Build for ARM64 (local development)
echo "Building for ARM64 (local development)..."
docker build --platform linux/arm64 -t ${IMAGE_NAME}:${TAG}-arm64 .

# Tag the AMD64 version as the main tag (for CodeBuild compatibility)
echo "Tagging AMD64 version as main tag..."
docker tag ${IMAGE_NAME}:${TAG}-amd64 ${IMAGE_NAME}:${TAG}

echo "Build completed!"
echo "Available tags:"
echo "  - ${IMAGE_NAME}:${TAG} (AMD64 - for CodeBuild)"
echo "  - ${IMAGE_NAME}:${TAG}-amd64 (AMD64 - for CodeBuild)"
echo "  - ${IMAGE_NAME}:${TAG}-arm64 (ARM64 - for local development)"

echo ""
echo "Test the images:"
echo "  docker run --rm ${IMAGE_NAME}:${TAG} \"node --version && terraform version\""
echo ""
echo "For CodeBuild, use: ${IMAGE_NAME}:${TAG} or ${IMAGE_NAME}:${TAG}-amd64"
