# CodeBuild Configuration Checklist for SINGLE_BUILD_CONTAINER_DEAD

## Required Settings:
1. **Compute Type**: BUILD_GENERAL1_MEDIUM (7 GB) or higher
   - SMALL (3 GB) might not be enough for Node.js + Terraform
   
2. **Environment Type**: Linux container

3. **Image**: Custom container
   - Use: `docker-node-terraform-aws:22.x` (now optimized for CodeBuild)
   - Fallback: `docker-node-terraform-aws:22.x-barebone` (if issues persist)

4. **Image Pull Behavior**: Always pull latest

## Common Causes & Solutions:

### Cause 1: Memory Issues
- **Symptoms**: Container dies during npm install or terraform init
- **Solution**: Increase compute type to MEDIUM or LARGE
- **Test**: Add memory monitoring to buildspec:
```yaml
pre_build:
  commands:
    - free -h
    - cat /proc/meminfo | grep MemAvailable
```

### Cause 2: Image Architecture Mismatch  
- **Symptoms**: Container fails to start immediately
- **Solution**: Ensure image is built for linux/amd64
- **Verify**: `docker inspect your-image | grep Architecture` should show `"Architecture": "amd64"`
- **Fix**: `docker build --platform linux/amd64 -t your-image:tag .`
- **⚠️ CRITICAL**: Even if you fixed this once, check again - Docker might rebuild for your local platform

### Cause 3: Entrypoint Issues
- **Symptoms**: Container starts then dies quickly
- **Solution**: Main Dockerfile now uses simple entrypoint (entrypoint-simple.sh)
- **Test**: Try barebone image with no custom entrypoint if issues persist

### Cause 4: Network/Registry Issues
- **Symptoms**: Cannot pull custom image
- **Solution**: Check ECR permissions or image availability
- **Test**: Try public images first

### Cause 5: Buildspec Errors
- **Symptoms**: Container dies during specific commands
- **Solution**: Simplify buildspec, add error handling
- **Test**: Use buildspec-minimal.yml

## Step-by-Step Debugging:

### 🚨 **EMERGENCY: Still Getting SINGLE_BUILD_CONTAINER_DEAD?**

**First, verify your image architecture:**
```bash
docker inspect docker-node-terraform-aws:22.x | grep Architecture
# MUST show: "Architecture": "amd64"
# If it shows "arm64", run: docker tag docker-node-terraform-aws:22.x-amd64 docker-node-terraform-aws:22.x
```

**Try these images in order:**

1. **Ultra-minimal test** (162MB - most likely to work):
   ```bash
   docker build --platform linux/amd64 -f Dockerfile.ultra-minimal -t test:ultra .
   ```

2. **Barebone image** (445MB - if ultra-minimal works):
   ```bash  
   docker build --platform linux/amd64 -f Dockerfile.barebone -t test:barebone .
   ```

3. **Full image** (616MB - if barebone works):
   ```bash
   docker build --platform linux/amd64 -t test:full .
   ```

**Ultra-minimal buildspec for testing:**
   ```yaml
   version: 0.2
   phases:
     install:
       commands:
         - echo "Container alive"
         - node --version
     build:
       commands:
         - echo "Build phase works"
   ```

4. **Check CodeBuild Settings**:
   - Compute: BUILD_GENERAL1_MEDIUM (7GB) minimum
   - Environment: Linux container
   - Image: Your ECR URI or Docker Hub image
   - Privileged: OFF (unless Docker-in-Docker needed)

### Original Debugging Steps:

1. **Test 1**: Use main optimized image with minimal buildspec
   - If this works → Issue is with your buildspec complexity
   - If this fails → Try barebone image next

2. **Test 2**: Use barebone image if main image fails
   - If barebone works → Issue is with package installation or entrypoint
   - If barebone fails → Issue is with CodeBuild configuration

3. **Test 3**: Gradually add complexity
   - Start with minimal buildspec, then add commands one by one
   - Monitor memory usage during each step

3. **Test 3**: Monitor resources
```yaml
phases:
  install:
    commands:
      - echo "=== System Info ==="
      - uname -a
      - cat /proc/meminfo | head -5
      - df -h
      - echo "=== Process Info ==="
      - ps aux | head -10
```

## Quick Fix Commands:

### Build commands for current setup:

```bash
# Main optimized image (recommended first try)
docker build --platform linux/amd64 -t docker-node-terraform-aws:22.x .

# Barebone fallback (if main image fails)
docker build --platform linux/amd64 -f Dockerfile.barebone -t docker-node-terraform-aws:barebone .
```

### Push to ECR for testing:

```bash
# Replace with your account/region
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

docker tag docker-node-terraform-aws:22.x 123456789012.dkr.ecr.us-east-1.amazonaws.com/docker-node-terraform-aws:22.x
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/docker-node-terraform-aws:22.x
```
