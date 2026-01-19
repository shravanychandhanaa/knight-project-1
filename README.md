# Knight Secured — CI/CD with Docker & Security Scans

Project demonstrating a secure CI/CD pipeline using GitHub Actions, Docker, Bandit, flake8 and Trivy. The pipeline builds, lints, scans Python code, builds a Docker image, scans the image for CRITICAL vulnerabilities, and deploys to an AWS EC2 VPS via SSH.

Files added:
- `app.py` — Hello-world Flask app
- `requirements.txt` — runtime deps
- `Dockerfile` — non-root image with Gunicorn
- `.github/workflows/ci-cd.yml` — GitHub Actions pipeline
- `check_bandit.py` — fail CI on HIGH/CRITICAL Bandit issues
- `.flake8`, `.dockerignore`

Quick local test
1. Build image locally:
```bash
docker build -t youruser/knight-secured:latest .
```
2. Run locally:
```bash
docker run -p 80:80 youruser/knight-secured:latest
```

GitHub setup (secrets)
- `DOCKER_HUB_USERNAME` — your Docker Hub username
- `DOCKER_HUB_ACCESS_TOKEN` — Docker Hub access token (or password)
- `DOCKER_REPO` — e.g. `youruser/knight-secured`
- `SSH_PRIVATE_KEY` — private key for EC2 user (no passphrase recommended)
- `SSH_HOST` — EC2 public IP
- `SSH_USER` — EC2 user (e.g., `ubuntu` for Ubuntu AMI)
- `SSH_PORT` — usually `22`

AWS EC2 (Free tier) setup summary
1. Create an EC2 instance (Ubuntu 22.04 LTS, t2.micro) in AWS Free Tier.
2. Security Group: allow inbound 22 (SSH) and 80 (HTTP) from your IP / 0.0.0.0/0 for 80.
3. SSH into instance:
```bash
ssh -i /path/to/yourkey.pem ubuntu@EC2_PUBLIC_IP
```
4. Install Docker on EC2 (Ubuntu):
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER
newgrp docker
```
5. (Optional) Test docker: `docker run --rm -p 80:80 youruser/knight-secured:latest`

How the workflow fails on security findings
- Bandit: `check_bandit.py` exits with non-zero if any HIGH/CRITICAL findings are present.
- Trivy: run with `--exit-code 1 --severity CRITICAL` to fail the job if any CRITICAL vulnerabilities exist.

Next steps for you
1. Create a Docker Hub repository (e.g., `youruser/knight-secured`).
2. Add the required GitHub repository Secrets listed above.
3. Push this repository to GitHub on branch `main` and watch the Actions run.
4. Ensure your EC2 instance has Docker installed and is reachable via `SSH_HOST`/`SSH_USER`.
