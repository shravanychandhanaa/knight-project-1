param(
  [Parameter(Mandatory=$true)][string]$SshUser,
  [Parameter(Mandatory=$true)][string]$SshHost,
  [Parameter(Mandatory=$true)][string]$SshKeyPath,
  [Parameter(Mandatory=$true)][string]$DockerRepo,
  [int]$SshPort = 22
)

if (-not $env:DOCKER_HUB_USERNAME -or -not $env:DOCKER_HUB_PASSWORD) {
  Write-Error "Please set DOCKER_HUB_USERNAME and DOCKER_HUB_PASSWORD environment variables"
  exit 3
}

$remoteDir = "/home/$SshUser/deployment_knight"

Write-Host "Creating archive of current directory..."
$zip = "$env:TEMP\knight_deploy.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path * -DestinationPath $zip

Write-Host "Copying project to remote host..."
scp -i $SshKeyPath -P $SshPort $zip $SshUser@$SshHost:$remoteDir.zip

Write-Host "Installing Docker and deploying on remote host..."
$installScript = @"
set -e
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker "$SshUser" || true
sudo systemctl enable docker || true
sudo systemctl start docker || true

mkdir -p $remoteDir && unzip -o $remoteDir.zip -d $remoteDir
echo "$($env:DOCKER_HUB_PASSWORD)" | sudo docker login -u "$($env:DOCKER_HUB_USERNAME)" --password-stdin
sudo docker build -t $DockerRepo:latest $remoteDir
sudo docker push $DockerRepo:latest
sudo docker stop knight_app || true
sudo docker rm knight_app || true
sudo docker run -d --name knight_app --restart unless-stopped -p 80:80 $DockerRepo:latest
rm -f $remoteDir.zip
rm -rf $remoteDir
"@

ssh -i $SshKeyPath -p $SshPort $SshUser@$SshHost $installScript

Write-Host "Deployment complete. Visit http://$SshHost/"
