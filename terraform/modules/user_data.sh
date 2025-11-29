#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Start Docker
systemctl start docker
systemctl enable docker

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt-get install -y unzip
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create auto-update script for checking ECR image changes every 3 minutes
cat > /usr/local/bin/check-ecr-updates.sh << 'EOF'
#!/bin/bash

CONTAINER_NAME="tx01-nginx"
ECR_REGISTRY="${ecr_registry}"
DOCKER_IMAGE="${docker_image}"
AWS_REGION="${aws_region}"
LOG_FILE="/var/log/ecr-auto-update.log"

# Function to get current running image digest
get_running_digest() {
  docker inspect "$CONTAINER_NAME" --format='{{.Image}}' 2>/dev/null | grep -oP '@sha256:\K[a-f0-9]{64}' || echo "none"
}

# Function to get latest ECR image digest and tag
get_ecr_latest() {
  aws ecr describe-images \
    --repository-name "$(echo $DOCKER_IMAGE | cut -d':' -f1)" \
    --region "$AWS_REGION" \
    --query 'sort_by(imageDetails, &imagePushedAt)[-1].[imageDigest,imageTags[0]]' \
    --output text 2>/dev/null || echo "error none"
}

# Main logic
{
  RUNNING_DIGEST=$(get_running_digest)
  read ECR_DIGEST ECR_TAG <<< $(get_ecr_latest)
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for ECR updates..."
  echo "Running: $RUNNING_DIGEST | ECR: $ECR_DIGEST (tag: $ECR_TAG)"
  
  if [ "$ECR_DIGEST" != "error" ] && [ "$ECR_DIGEST" != "none" ] && [ "$RUNNING_DIGEST" != "$ECR_DIGEST" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ New image detected! Updating..."
    
    REPO_NAME=$(echo $DOCKER_IMAGE | cut -d':' -f1)
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY" >> "$LOG_FILE" 2>&1
    
    # Pull new image by tag
    docker pull "$ECR_REGISTRY/$REPO_NAME:$ECR_TAG" >> "$LOG_FILE" 2>&1
    
    # Stop old container
    docker stop "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    docker rm "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    
    # Run new container
    docker run -d \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -p 80:80 \
      "$ECR_REGISTRY/$REPO_NAME:$ECR_TAG" >> "$LOG_FILE" 2>&1
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Container updated successfully!"
    
    # Health check
    sleep 5
    if curl -f http://localhost:80/health > /dev/null 2>&1; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ New container is healthy" >> "$LOG_FILE"
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ New container is NOT responding to health check" >> "$LOG_FILE"
    fi
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No updates needed"
  fi
} >> "$LOG_FILE" 2>&1
EOF

chmod +x /usr/local/bin/check-ecr-updates.sh

# Install cron and setup cronjob to run every 3 minutes
apt-get install -y cron
systemctl start cron
systemctl enable cron

# Add cronjob: run every 3 minutes
(crontab -l 2>/dev/null; echo "*/3 * * * * /usr/local/bin/check-ecr-updates.sh") | crontab -

echo "✅ Auto-update cronjob installed (runs every 3 minutes)" | tee -a /var/log/container-startup.log

# Login to ECR and pull image
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}

# Pull and run container on port 80 (directly accessible by ALB)
docker pull ${ecr_registry}/${docker_image}
docker run -d \
  --name tx01-nginx \
  --restart unless-stopped \
  -p 80:80 \
  ${ecr_registry}/${docker_image}

# Health check
sleep 10
if curl -f http://localhost:80/health > /dev/null 2>&1; then
  echo "✅ Container healthy" | tee -a /var/log/container-startup.log
else
  echo "⚠️ Container not responding" | tee -a /var/log/container-startup.log
fi
