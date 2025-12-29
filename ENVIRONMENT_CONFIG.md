# Environment Configuration Guide

## 🌍 Multi-Environment Support

The deployment scripts now support **both dev and prod environments** dynamically!

## 🔧 How It Works

### Environment Variable
The `ENV` environment variable controls which environment to deploy to:
- **`dev`** (default) - Development environment
- **`prod`** - Production environment

### Dynamic Path Resolution
```bash
# In ssh.sh
ENVIRONMENT="${ENV:-dev}"
TERRAFORM_DIR="/var/lib/jenkins/workspace/url-infra/labs/${ENVIRONMENT}"
```

This means:
- If `ENV=dev` → uses `/var/lib/jenkins/workspace/url-infra/labs/dev`
- If `ENV=prod` → uses `/var/lib/jenkins/workspace/url-infra/labs/prod`
- If `ENV` not set → defaults to `dev`

## 🚀 Usage

### From Jenkins (Recommended)

1. Navigate to `deploy-app` job
2. Click **"Build with Parameters"**
3. Select environment from dropdown:
   - `dev` for development
   - `prod` for production
4. Click **"Build"**

Jenkins will automatically pass the `ENV` variable to the scripts.

### Manual Execution

```bash
# Deploy to dev (default)
./main.sh

# Or explicitly set dev
ENV=dev ./main.sh

# Deploy to prod
ENV=prod ./main.sh
```

## 📋 Prerequisites Per Environment

### Dev Environment
- Terraform state at: `/var/lib/jenkins/workspace/url-infra/labs/dev/`
- Dev EC2 instance created by `deploy-infra` job (dev)
- Dev security groups configured

### Prod Environment
- Terraform state at: `/var/lib/jenkins/workspace/url-infra/labs/prod/`
- Prod EC2 instance created by `deploy-infra` job (prod)
- Prod security groups configured
- **Additional considerations**:
  - Higher instance type
  - Multi-AZ deployment
  - Enhanced monitoring
  - Backup policies

## 🔄 Deployment Workflow

### Development Deployment
```bash
1. Run deploy-infra job with ENV=dev
2. Run deploy-app job with ENV=dev
3. Test on dev EC2 instance
```

### Production Deployment
```bash
1. Test thoroughly in dev environment first
2. Run deploy-infra job with ENV=prod
3. Run deploy-app job with ENV=prod
4. Verify on prod EC2 instance
5. Monitor application health
```

## 🎯 Jenkins Job Configuration

The `deploy-app.xml` now includes a parameter definition:

```xml
<hudson.model.ChoiceParameterDefinition>
  <name>ENV</name>
  <description>Select the environment to deploy to</description>
  <choices class="java.util.Arrays$ArrayList">
    <a class="string-array">
      <string>dev</string>
      <string>prod</string>
    </a>
  </choices>
</hudson.model.ChoiceParameterDefinition>
```

This creates a dropdown menu in Jenkins UI for environment selection.

## 🔍 Verification

### Check Current Environment
When running the deployment, look for these log lines:
```
[TIMESTAMP] 🌍 Environment: dev
[TIMESTAMP] 📁 Terraform Directory: /var/lib/jenkins/workspace/url-infra/labs/dev
```

### Verify Correct EC2
```bash
# For dev
cd /var/lib/jenkins/workspace/url-infra/labs/dev
terraform output public_ip

# For prod
cd /var/lib/jenkins/workspace/url-infra/labs/prod
terraform output public_ip
```

## 🐛 Troubleshooting

### Issue: Deploying to wrong environment
**Symptom**: Scripts run but deploy to wrong EC2
**Solution**: Check Jenkins parameter selection or ENV variable value

### Issue: Terraform directory not found
**Symptom**: `❌ Terraform directory not found`
**Solution**: 
1. Ensure `deploy-infra` job was run for that environment
2. Check path exists: `ls -la /var/lib/jenkins/workspace/url-infra/labs/`
3. Verify environment spelling (dev/prod, case-sensitive)

### Issue: Wrong infrastructure
**Symptom**: Deploying app to EC2 from different environment
**Solution**: Always run jobs in order:
1. `deploy-infra` with ENV=X
2. `deploy-app` with ENV=X (same value)

## 🔐 Security Best Practices

### Environment Separation
- **Dev**: Use separate AWS account or VPC
- **Prod**: Strict access controls, no direct SSH
- **SSH Keys**: Use different keys per environment (optional enhancement)

### Suggested Enhancement
```bash
# In ssh.sh, use environment-specific keys:
SSH_KEY="/var/lib/jenkins/.ssh/url_app_${ENVIRONMENT}.pem"
# This would require:
# - url_app_dev.pem for dev
# - url_app_prod.pem for prod
```