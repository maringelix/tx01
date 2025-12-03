#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install SSM Agent (para Ubuntu 22.04)
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

# Install Docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq

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

# Login to ECR and pull image
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}

# Pull and run container (with retry logic)
MAX_RETRIES=5
RETRY_COUNT=0
IMAGE_PULLED=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$IMAGE_PULLED" = false ]; do
  if docker pull ${ecr_registry}/${docker_image}; then
    IMAGE_PULLED=true
    echo "✅ Image pulled successfully" | tee -a /var/log/container-startup.log
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "⚠️ Image pull attempt $RETRY_COUNT failed. Retrying in 30s..." | tee -a /var/log/container-startup.log
    sleep 30
  fi
done

if [ "$IMAGE_PULLED" = true ]; then
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
else
  echo "❌ Failed to pull image after $MAX_RETRIES attempts" | tee -a /var/log/container-startup.log
  echo "Container will start when image becomes available" | tee -a /var/log/container-startup.log
fi

# Setup cron job to check for new images every 5 minutes
cat > /usr/local/bin/update-container.sh << 'EOF'
#!/bin/bash
ECR_REGISTRY="${ecr_registry}"
DOCKER_IMAGE="${docker_image}"
AWS_REGION="${aws_region}"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY 2>/dev/null

# Pull latest image
docker pull $ECR_REGISTRY/$DOCKER_IMAGE > /dev/null 2>&1

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q '^tx01-nginx$'; then
  # Get current image ID
  CURRENT_IMAGE=$(docker inspect tx01-nginx --format='{{.Image}}')
  LATEST_IMAGE=$(docker images $ECR_REGISTRY/$DOCKER_IMAGE --format='{{.ID}}' | head -1)
  
  if [ "$CURRENT_IMAGE" != "$LATEST_IMAGE" ]; then
    echo "$(date): New image detected, updating container..." >> /var/log/container-updates.log
    docker stop tx01-nginx
    docker rm tx01-nginx
    docker run -d --name tx01-nginx --restart unless-stopped -p 80:80 $ECR_REGISTRY/$DOCKER_IMAGE
    echo "$(date): Container updated successfully" >> /var/log/container-updates.log
  fi
else
  # Container doesn't exist, try to start it
  echo "$(date): Container not found, starting..." >> /var/log/container-updates.log
  docker run -d --name tx01-nginx --restart unless-stopped -p 80:80 $ECR_REGISTRY/$DOCKER_IMAGE 2>/dev/null
fi
EOF

chmod +x /usr/local/bin/update-container.sh

# Add cron job (every 5 minutes)
echo "*/5 * * * * /usr/local/bin/update-container.sh" | crontab -
