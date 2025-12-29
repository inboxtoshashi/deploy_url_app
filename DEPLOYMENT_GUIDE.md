# Quick Deployment Guide

## 🎯 Quick Start

This repository is ready for Jenkins automation! The `deploy-app` Jenkins job will handle everything automatically.

## ✅ Pre-Deployment Checklist

Before running the `deploy-app` job, ensure:

### 1. Infrastructure is Ready
```bash
# Run the deploy-infra job first
# This creates the EC2 instance using Terraform
```
- [ ] `url-infra` job executed successfully
- [ ] EC2 instance is running
- [ ] Terraform outputs are available

### 2. Jenkins Configuration
- [ ] SSH key exists at: `/var/lib/jenkins/.ssh/url_app.pem`
- [ ] SSH key has correct permissions: `chmod 600 url_app.pem`
- [ ] Jenkins has network access to EC2 instance

### 3. EC2 Instance Configuration
- [ ] Security group allows SSH (port 22) from Jenkins server
- [ ] Security group allows application ports (typically 80, 443, or custom)
- [ ] EC2 instance has internet access for package downloads
- [ ] Ubuntu-based AMI with git pre-installed

## 🚀 Deployment Steps

### Option 1: Jenkins Job (Recommended)
1. Navigate to Jenkins dashboard
2. Click on `deploy-app` job
3. Click "Build with Parameters"
4. **Select Environment**: Choose `dev` or `prod`
5. Click "Build"
6. Monitor console output

### Option 2: Manual Execution (Testing)
```bash
# Clone the repository
git clone https://github.com/inboxtoshashi/deploy_url_app.git
cd deploy_url_app

# Make main.sh executable (already done in repo)
chmod +x main.sh

# Execute deployment to dev (default)
./main.sh

# Or deploy to prod
ENV=prod ./main.sh
```

## 📊 What Happens During Deployment

### Phase 1: Connection (ssh.sh)
```
✓ Retrieve EC2 IP from Terraform
✓ Validate SSH key
✓ Copy scripts to EC2
✓ Establish SSH connection
```

### Phase 2: Environment Setup (download_docker.sh)
```
✓ Check if Docker is installed
✓ Clone docker_requirements repo
✓ Install Docker & Docker Compose
✓ Configure Docker service
✓ Add user to docker group
```

### Phase 3: Application Deployment (deploy_app.sh)
```
✓ Clone urlshortener_docker repo
✓ Stop existing containers
✓ Build Docker images
✓ Start containers
✓ Verify container health
```

## 📋 Post-Deployment Verification

### 1. Check Jenkins Console Output
Look for these success messages:
```
✅ EC2 Public IP is x.x.x.x
✅ Docker installed successfully
✅ All containers are running successfully!
✅ Deployment completed successfully!
```

### 2. Verify on EC2 Instance
```bash
# SSH into EC2
ssh -i /var/lib/jenkins/.ssh/url_app.pem ubuntu@<EC2_IP>

# Check Docker is running
docker --version
sudo systemctl status docker

# Check containers
docker ps

# View application logs
cd urlshortener_docker
docker compose -f urlShortner.yml logs

# Test application (replace PORT with your app port)
curl http://localhost:PORT
```

### 3. Access the Application
```bash
# From browser or curl
http://<EC2_PUBLIC_IP>:<APP_PORT>
```

## 🐛 Troubleshooting Quick Fixes

### Issue: "Failed to retrieve EC2 public IP"
```bash
# Check Terraform state for correct environment
cd /var/lib/jenkins/workspace/url-infra/labs/dev  # or prod
terraform output public_ip

# Make sure you deployed to the correct environment
# If deploying to prod, ensure ENV=prod was set
```

### Issue: "SSH connection failed"
```bash
# Check SSH key permissions
ls -la /var/lib/jenkins/.ssh/url_app.pem

# Test SSH manually
ssh -i /var/lib/jenkins/.ssh/url_app.pem ubuntu@<EC2_IP>

# Check security group
# Ensure port 22 is open from Jenkins server IP
```

### Issue: "Docker installation failed"
```bash
# SSH into EC2 and check
sudo apt update
sudo apt install -y docker.io

# Check for disk space
df -h

# Check internet connectivity
ping -c 4 google.com
```

### Issue: "Container build failed"
```bash
# On EC2 instance
cd urlshortener_docker

# Check Docker Compose file
cat urlShortner.yml

# Try building manually
docker compose -f urlShortner.yml build

# Check Docker logs
docker compose -f urlShortner.yml logs
```

## 🔄 Re-Deployment

To re-deploy the application:
1. Simply run the `deploy-app` job again
2. The scripts will:
   - Skip Docker installation if already present
   - Pull latest code from git
   - Stop existing containers
   - Rebuild and restart containers

## 🔧 Configuration Changes

### Update Terraform Directory
Edit `ssh_url_ec2/ssh.sh`:
```bash
TERRAFORM_DIR="/var/lib/jenkins/workspace/url-infra/labs/dev"
```

### Update SSH Key Location
Edit `ssh_url_ec2/ssh.sh`:
```bash
SSH_KEY="/var/lib/jenkins/.ssh/url_app.pem"
```

### Update Application Repository
Edit `deploy_app/deploy_app.sh`:
```bash
REPO_URL="https://github.com/inboxtoshashi/urlshortener_docker.git"
```

## 📞 Emergency Procedures

### Stop All Containers
```bash
ssh -i /var/lib/jenkins/.ssh/url_app.pem ubuntu@<EC2_IP>
cd urlshortener_docker
docker compose -f urlShortner.yml down
```

### View Real-Time Logs
```bash
ssh -i /var/lib/jenkins/.ssh/url_app.pem ubuntu@<EC2_IP>
cd urlshortener_docker
docker compose -f urlShortner.yml logs -f
```

### Clean Rebuild
```bash
ssh -i /var/lib/jenkins/.ssh/url_app.pem ubuntu@<EC2_IP>
cd urlshortener_docker
docker compose -f urlShortner.yml down -v  # Remove volumes
docker system prune -a -f                   # Clean all Docker resources
# Then re-run deploy-app job
```

## 🎓 Key Points to Remember

1. **Always run `deploy-infra` job before `deploy-app`**
2. **EC2 must have internet access** for package downloads
3. **Security groups must allow** SSH from Jenkins and app ports from users
4. **SSH key permissions** must be 600 (read/write for owner only)
5. **Docker group changes** may require a new SSH session to take effect

## ✨ Success Indicators

Everything is working when you see:
- ✅ Jenkins job shows "SUCCESS"
- ✅ `docker ps` shows running containers on EC2
- ✅ Application responds to HTTP requests
- ✅ No error messages in container logs

---

**Next Steps**: After successful deployment, consider setting up monitoring using the `deploy-monitoring` job!
