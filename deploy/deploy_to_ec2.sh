#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <SSH_USER> <SSH_HOST> <SSH_KEY_PATH> <DOCKER_REPO> [SSH_PORT]"
  echo "Requires env vars: DOCKER_HUB_USERNAME, DOCKER_HUB_PASSWORD"
  exit 2
fi

SSH_USER="$1"
SSH_HOST="$2"
SSH_KEY="$3"
DOCKER_REPO="$4"
SSH_PORT="${5:-22}"
REMOTE_DIR="/home/${SSH_USER}/deployment_knight"

if [ -z "${DOCKER_HUB_USERNAME:-}" ] || [ -z "${DOCKER_HUB_PASSWORD:-}" ]; then
  echo "Please set DOCKER_HUB_USERNAME and DOCKER_HUB_PASSWORD environment variables"
  exit 3
fi

echo "Uploading project to ${SSH_USER}@${SSH_HOST}:${REMOTE_DIR}..."
tar -czf - . | ssh -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_DIR && tar -xzf - -C $REMOTE_DIR"

echo "Installing Docker and building image on remote host..."
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" bash -s <<EOF
set -e
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \\$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker "$SSH_USER" || true
sudo systemctl enable docker || true
sudo systemctl start docker || true

echo "Logging in to Docker Hub..."
echo "${DOCKER_HUB_PASSWORD}" | sudo docker login -u "${DOCKER_HUB_USERNAME}" --password-stdin

echo "Building Docker image..."
sudo docker build -t ${DOCKER_REPO}:latest "$REMOTE_DIR"

echo "Pushing Docker image to Docker Hub..."
sudo docker push ${DOCKER_REPO}:latest

echo "Deploying container..."
sudo docker stop knight_app || true
sudo docker rm knight_app || true
sudo docker run -d --name knight_app --restart unless-stopped -p 80:80 ${DOCKER_REPO}:latest

echo "Cleaning up upload directory..."
rm -rf "$REMOTE_DIR"
EOF

echo "Deployment complete. Visit http://${SSH_HOST}/"
