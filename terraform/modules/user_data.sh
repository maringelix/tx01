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
apt-get install -y unzip jq
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Fetch database credentials from Secrets Manager
DB_SECRET_ARN="${db_secret_arn}"
if [ -n "$DB_SECRET_ARN" ]; then
  echo "Fetching database credentials from Secrets Manager..." | tee -a /var/log/container-startup.log
  DB_CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --region ${aws_region} --query SecretString --output text)
  
  export DB_HOST=$(echo $DB_CREDENTIALS | jq -r .host)
  export DB_PORT=$(echo $DB_CREDENTIALS | jq -r .port)
  export DB_NAME=$(echo $DB_CREDENTIALS | jq -r .dbname)
  export DB_USER=$(echo $DB_CREDENTIALS | jq -r .username)
  export DB_PASSWORD=$(echo $DB_CREDENTIALS | jq -r .password)
  
  echo "✅ Database credentials loaded" | tee -a /var/log/container-startup.log
fi

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
    
    # Fetch database credentials from Secrets Manager
    DB_SECRET_ARN="${db_secret_arn}"
    if [ -n "$DB_SECRET_ARN" ]; then
      DB_CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --region "$AWS_REGION" --query SecretString --output text 2>/dev/null)
      DB_HOST=$(echo $DB_CREDENTIALS | jq -r .host)
      DB_PORT=$(echo $DB_CREDENTIALS | jq -r .port)
      DB_NAME=$(echo $DB_CREDENTIALS | jq -r .dbname)
      DB_USER=$(echo $DB_CREDENTIALS | jq -r .username)
      DB_PASSWORD=$(echo $DB_CREDENTIALS | jq -r .password)
    fi
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY" >> "$LOG_FILE" 2>&1
    
    # Pull new image by tag
    docker pull "$ECR_REGISTRY/$REPO_NAME:$ECR_TAG" >> "$LOG_FILE" 2>&1
    
    # Stop old container
    docker stop "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    docker rm "$CONTAINER_NAME" >> "$LOG_FILE" 2>&1
    
    # Run new container with database env vars if available
    if [ -n "$DB_HOST" ]; then
      docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 80:80 \
        -e DB_HOST="$DB_HOST" \
        -e DB_PORT="$DB_PORT" \
        -e DB_NAME="$DB_NAME" \
        -e DB_USER="$DB_USER" \
        -e DB_PASSWORD="$DB_PASSWORD" \
        "$ECR_REGISTRY/$REPO_NAME:$ECR_TAG" >> "$LOG_FILE" 2>&1
    else
      docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 80:80 \
        "$ECR_REGISTRY/$REPO_NAME:$ECR_TAG" >> "$LOG_FILE" 2>&1
    fi
    
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

# Add cronjob: run ECR check every 3 minutes
(crontab -l 2>/dev/null; echo "*/3 * * * * /usr/local/bin/check-ecr-updates.sh") | crontab -

# Add cronjob: refresh DB env and restart container if DB_HOST missing (every 2 minutes)
cat > /usr/local/bin/refresh-db-env.sh << 'EOF'
#!/bin/bash
CONTAINER_NAME="tx01-nginx"
AWS_REGION="${aws_region}"
DB_SECRET_ARN="${db_secret_arn}"
LOG_FILE="/var/log/db-env-refresh.log"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking DB env and secret..."
  if [ -z "$DB_SECRET_ARN" ]; then
    echo "Secret ARN not set; skipping"
    exit 0
  fi

  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$DB_SECRET_ARN" --region "$AWS_REGION" --query SecretString --output text 2>/dev/null || echo "")
  HOST=$(echo "$SECRET_JSON" | jq -r .host 2>/dev/null)
  PORT=$(echo "$SECRET_JSON" | jq -r .port 2>/dev/null)
  NAME=$(echo "$SECRET_JSON" | jq -r .dbname 2>/dev/null)
  USER=$(echo "$SECRET_JSON" | jq -r .username 2>/dev/null)
  PASS=$(echo "$SECRET_JSON" | jq -r .password 2>/dev/null)

  if [ -z "$HOST" ] || [ "$HOST" = "null" ]; then
    echo "DB host not yet available; will retry later"
    exit 0
  fi

  # Check current container env for DB_HOST
  CURRENT_HOST=$(docker inspect "$CONTAINER_NAME" --format='{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^DB_HOST=' | cut -d'=' -f2)
  if [ -z "$CURRENT_HOST" ] || [ "$CURRENT_HOST" = "null" ]; then
    echo "Injecting DB env and restarting container..."
    IMAGE=$(docker inspect "$CONTAINER_NAME" --format='{{.Config.Image}}' 2>/dev/null)
    if [ -z "$IMAGE" ]; then
      echo "Container not found; nothing to restart"
      exit 0
    fi
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker run -d \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      -p 80:80 \
      -e DB_HOST="$HOST" \
      -e DB_PORT="$PORT" \
      -e DB_NAME="$NAME" \
      -e DB_USER="$USER" \
      -e DB_PASSWORD="$PASS" \
      "$IMAGE"
    echo "Container restarted with DB env"
  else
    echo "Container already has DB env; nothing to do"
  fi
} >> "$LOG_FILE" 2>&1
EOF

chmod +x /usr/local/bin/refresh-db-env.sh
(crontab -l 2>/dev/null; echo "*/2 * * * * /usr/local/bin/refresh-db-env.sh") | crontab -

echo "✅ Auto-update cronjob installed (runs every 3 minutes)" | tee -a /var/log/container-startup.log

# Login to ECR and pull image
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_registry}

# Pull and run container on port 80 (directly accessible by ALB)
docker pull ${ecr_registry}/${docker_image}

# Run container with database environment variables if available
if [ -n "$DB_HOST" ]; then
  docker run -d \
    --name tx01-nginx \
    --restart unless-stopped \
    -p 80:80 \
    -e DB_HOST="$DB_HOST" \
    -e DB_PORT="$DB_PORT" \
    -e DB_NAME="$DB_NAME" \
    -e DB_USER="$DB_USER" \
    -e DB_PASSWORD="$DB_PASSWORD" \
    ${ecr_registry}/${docker_image}
else
  docker run -d \
    --name tx01-nginx \
    --restart unless-stopped \
    -p 80:80 \
    ${ecr_registry}/${docker_image}
fi

# Health check
sleep 10
if curl -f http://localhost:80/health > /dev/null 2>&1; then
  echo "✅ Container healthy" | tee -a /var/log/container-startup.log
else
  echo "⚠️ Container not responding" | tee -a /var/log/container-startup.log
fi
