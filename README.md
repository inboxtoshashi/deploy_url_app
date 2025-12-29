# Deploy URL Shortener App

This repository contains automation scripts to deploy a URL Shortener application on AWS EC2 instances. It's designed to be triggered by Jenkins as part of a CI/CD pipeline.

## 📋 Overview

This deployment automation:
1. Retrieves EC2 instance details from Terraform outputs (infrastructure created by `url_infra`)
2. Copies deployment scripts to the EC2 instance via SSH
3. Installs Docker and Docker Compose on the EC2 instance
4. Clones and deploys the URL Shortener application using Docker containers

## 🏗️ Architecture

```
deploy_url_app/
├── main.sh                          # Main orchestration script (triggered by Jenkins)
├── ssh_url_ec2/
│   └── ssh.sh                       # Handles SSH connection and remote script execution
├── install_requirements/
│   └── download_docker.sh           # Installs Docker on EC2
└── deploy_app/
    └── deploy_app.sh                # Deploys the URL Shortener app
```

## 🔄 Workflow

### Jenkins Pipeline Trigger
The `deploy-app` Jenkins job will:
1. Clone this repository
2. Execute `main.sh`

### Deployment Flow
```
main.sh → ssh.sh → [EC2 Instance]
                      ├── download_docker.sh (Install Docker)
                      └── deploy_app.sh (Deploy application)
```

## 📝 Prerequisites

### On Jenkins Server
- Terraform outputs available at `/var/lib/jenkins/workspace/url-infra/labs/dev/`
- SSH private key at `/var/lib/jenkins/.ssh/url_app.pem`
- Git installed
- SSH client installed

### On EC2 Instance
- Ubuntu-based AMI
- Security group allowing SSH (port 22) from Jenkins server
- Security group allowing application ports (as defined in Docker Compose)
- SSM/IAM role configured (optional, for AWS Systems Manager access)

## 🚀 Usage

### Automated (Jenkins)
The deployment is automatically triggered by the Jenkins `deploy-app` job:
```bash
# Jenkins job will prompt for environment selection (dev or prod)
# Then execute:
ENV=${ENV} ./main.sh
```

### Manual Testing
For testing purposes, you can run manually:
```bash
cd deploy_url_app
chmod +x main.sh

# Deploy to dev environment (default)
./main.sh

# Deploy to prod environment
ENV=prod ./main.sh
```

## 📂 Script Details

### main.sh
- **Purpose**: Entry point that orchestrates the deployment
- **What it does**: Calls `ssh.sh` to handle remote deployment
- **Exit codes**: 0 (success), 1 (failure)

### ssh_url_ec2/ssh.sh
- **Purpose**: Manages SSH connection and remote script execution
- **Dependencies**: 
  - Terraform CLI
  - SSH client
  - Valid SSH key
- **What it does**:
  1. Retrieves EC2 public IP from Terraform outputs
  2. Copies `download_docker.sh` and `deploy_app.sh` to EC2
  3. SSH into EC2 and executes both scripts remotely
  4. Handles line ending conversion (dos2unix)

### install_requirements/download_docker.sh
- **Purpose**: Installs Docker and Docker Compose on EC2
- **Repository**: Clones from `inboxtoshashi/docker_requirements`
- **What it does**:
  - Checks if Docker is already installed
  - Clones installation scripts repository
  - Runs Docker installation
  - Configures Docker service
  - Adds user to docker group

### deploy_app/deploy_app.sh
- **Purpose**: Deploys the URL Shortener application
- **Repository**: Clones from `inboxtoshashi/urlshortener_docker`
- **What it does**:
  - Clones/updates the application repository
  - Stops existing containers (if any)
  - Builds Docker images with no cache
  - Starts containers in detached mode
  - Verifies container health

## 🔧 Configuration

### Key Variables in ssh.sh
```bash
ENVIRONMENT="${ENV:-dev}"  # Environment (dev or prod), defaults to dev
TERRAFORM_DIR="/var/lib/jenkins/workspace/url-infra/labs/${ENVIRONMENT}"
SSH_KEY="${SSH_KEY_PATH:-$HOME/.ssh/url_app.pem}"  # Configurable SSH key path
REMOTE_USER="ubuntu"
```

### Environment Variables

The deployment can be configured via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ENV` | Environment to deploy to (dev/prod) | `dev` |
| `SSH_KEY_PATH` | Path to SSH private key | `$HOME/.ssh/url_app.pem` |

### Passing Environment Variables
```bash
# From Jenkins (automatic via parameter)
export SSH_KEY_PATH="/var/lib/jenkins/.ssh/url_app.pem"
ENV=prod ./main.sh

# Manual execution with custom SSH key
SSH_KEY_PATH="/path/to/your/key.pem" ENV=dev ./main.sh

# Using default SSH key location
ENV=prod ./main.sh
```

### Application Variables in deploy_app.sh
```bash
REPO_URL="https://github.com/inboxtoshashi/urlshortener_docker.git"
DOCKER_COMPOSE_FILE="urlShortner.yml"
```

## 🐛 Troubleshooting

### Common Issues

**Issue**: SSH connection failed
- **Solution**: Verify EC2 security group allows SSH from Jenkins server
- **Solution**: Check SSH key permissions: `chmod 600 /var/lib/jenkins/.ssh/url_app.pem`

**Issue**: Terraform output not found
- **Solution**: Ensure `url-infra` job has run successfully
- **Solution**: Verify Terraform state exists in the specified directory

**Issue**: Docker installation failed
- **Solution**: Check EC2 instance has internet access
- **Solution**: Verify EC2 instance role/permissions for package downloads

**Issue**: Container build failed
- **Solution**: Check Docker logs: `docker logs <container_id>`
- **Solution**: Verify application repository is accessible
- **Solution**: Check EC2 instance resources (disk space, memory)

### Viewing Logs
On EC2 instance:
```bash
# View running containers
docker ps

# View container logs
docker compose -f urlshortener_docker/urlShortner.yml logs

# View specific container logs
docker logs <container_name>
```

## 🔐 Security Considerations

1. **SSH Keys**: Ensure private keys are stored securely with appropriate permissions
2. **Security Groups**: Limit SSH access to Jenkins server IP only
3. **Secrets**: Use Jenkins credentials or AWS Secrets Manager for sensitive data
4. **User Permissions**: Run with least privilege necessary

## 🔗 Related Repositories

- **url_infra**: Terraform infrastructure code for creating EC2 instances
- **dvm-setup**: Jenkins Docker setup and job configurations
- **docker_requirements**: Docker installation scripts
- **urlshortener_docker**: URL Shortener application with Docker Compose

## 📞 Support

For issues or questions:
1. Check Jenkins job console output for detailed logs
2. SSH into EC2 and check `/var/log/cloud-init-output.log`
3. Review Docker container logs
4. Verify Terraform state and outputs

## 🎯 Success Criteria

Deployment is successful when:
- ✅ SSH connection to EC2 established
- ✅ Docker and Docker Compose installed
- ✅ Application containers built without errors
- ✅ All containers running in healthy state
- ✅ Application accessible on expected ports
