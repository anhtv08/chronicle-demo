# Chronicle Demo - AWS Deployment Guide

This guide provides step-by-step instructions for deploying the Chronicle Map/Queue demo application to AWS using Infrastructure as Code (Terraform) and containerized deployment (ECS Fargate).

## 🏗️ Architecture Overview

The deployment creates a production-ready, scalable architecture on AWS:

### Infrastructure Components

- **VPC**: Custom VPC with public and private subnets across multiple AZs
- **ECS Fargate**: Serverless container platform for running the application
- **Application Load Balancer**: Distributes traffic across multiple container instances
- **EFS**: Persistent storage for Chronicle data files
- **ECR**: Container registry for Docker images
- **CloudWatch**: Centralized logging and monitoring
- **Auto Scaling**: Automatic scaling based on CPU and memory utilization

### Architecture Diagram

```
Internet Gateway
       |
   [ALB] (Public Subnets)
       |
   [ECS Fargate] (Private Subnets)
       |
   [EFS] (Persistent Storage)
```

## 📋 Prerequisites

### Required Tools

1. **AWS CLI** (v2.x recommended)
   ```bash
   # Install via Homebrew (macOS)
   brew install awscli
   
   # Or download from: https://aws.amazon.com/cli/
   ```

2. **Terraform** (v1.0+)
   ```bash
   # Install via Homebrew (macOS)
   brew install terraform
   
   # Or download from: https://www.terraform.io/downloads
   ```

3. **Docker** (for building images)
   ```bash
   # Install Docker Desktop
   # https://www.docker.com/products/docker-desktop/
   ```

4. **Maven** (for building the Java application)
   ```bash
   # Install via Homebrew (macOS)
   brew install maven
   ```

### AWS Configuration

1. **Configure AWS Credentials**
   ```bash
   aws configure
   ```
   
   You'll need:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., `us-west-2`)
   - Default output format (`json`)

2. **Verify AWS Access**
   ```bash
   aws sts get-caller-identity
   ```

## 🚀 Deployment Steps

### Step 1: Clone and Prepare the Repository

```bash
git clone <repository-url>
cd chronicle-demo
```

### Step 2: Deploy Infrastructure

```bash
# Make deployment scripts executable
chmod +x deploy/*.sh

# Deploy AWS infrastructure
./deploy/deploy-infrastructure.sh
```

This script will:
- Initialize Terraform
- Validate the configuration
- Show you the deployment plan
- Ask for confirmation
- Deploy all AWS resources

**Expected deployment time: 5-10 minutes**

### Step 3: Build and Push Docker Image

```bash
# Build application and push to ECR
./deploy/build-and-push.sh
```

This script will:
- Build the Maven application
- Create a Docker image
- Create ECR repository (if needed)
- Push the image to ECR
- Tag with both `latest` and timestamp

### Step 4: Wait for Service Deployment

After pushing the image, ECS will automatically deploy the new version:

```bash
# Monitor the deployment
aws ecs describe-services \
  --cluster chronicle-demo-cluster \
  --services chronicle-demo-service \
  --query 'services[0].deployments'
```

### Step 5: Access the Application

Once deployed, get the load balancer URL:

```bash
cd terraform
terraform output load_balancer_url
```

The application will be available at: `http://<load-balancer-dns>/`

## 📊 Monitoring and Management

### View Application Logs

```bash
# Stream logs in real-time
aws logs tail /ecs/chronicle-demo --follow

# View specific log stream
aws logs describe-log-streams --log-group-name /ecs/chronicle-demo
```

### Monitor ECS Service

```bash
# Check service status
aws ecs describe-services \
  --cluster chronicle-demo-cluster \
  --services chronicle-demo-service

# View running tasks
aws ecs list-tasks \
  --cluster chronicle-demo-cluster \
  --service-name chronicle-demo-service
```

### Scale the Service

```bash
# Scale to 3 instances
aws ecs update-service \
  --cluster chronicle-demo-cluster \
  --service chronicle-demo-service \
  --desired-count 3
```

### Force New Deployment

```bash
# Deploy latest image version
aws ecs update-service \
  --cluster chronicle-demo-cluster \
  --service chronicle-demo-service \
  --force-new-deployment
```

## 🔧 Configuration

### Environment Variables

The application supports these environment variables:

- `JAVA_OPTS`: JVM options for Chronicle optimization
- `AWS_REGION`: AWS region for services
- `LOG_LEVEL`: Application log level

### Terraform Variables

Key variables in `terraform/variables.tf`:

```hcl
# Scaling configuration
variable "ecs_desired_count" {
  default = 2  # Number of running tasks
}

variable "ecs_task_cpu" {
  default = 1024  # CPU units (1 vCPU = 1024)
}

variable "ecs_task_memory" {
  default = 2048  # Memory in MB
}

# Auto scaling thresholds
variable "target_cpu_utilization" {
  default = 70  # Scale up when CPU > 70%
}
```

### Custom Deployment

For custom configurations:

```bash
cd terraform

# Deploy with custom variables
terraform apply \
  -var="ecs_desired_count=3" \
  -var="ecs_task_memory=4096" \
  -var="aws_region=us-east-1"
```

## 🔍 Troubleshooting

### Common Issues

1. **ECS Tasks Failing to Start**
   ```bash
   # Check task definition
   aws ecs describe-task-definition --task-definition chronicle-demo-task
   
   # Check stopped tasks
   aws ecs describe-tasks \
     --cluster chronicle-demo-cluster \
     --tasks $(aws ecs list-tasks --cluster chronicle-demo-cluster --desired-status STOPPED --query 'taskArns[0]' --output text)
   ```

2. **Load Balancer Health Checks Failing**
   ```bash
   # Check target group health
   aws elbv2 describe-target-health \
     --target-group-arn $(aws elbv2 describe-target-groups --names chronicle-demo-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
   ```

3. **Image Pull Errors**
   ```bash
   # Verify ECR repository
   aws ecr describe-repositories --repository-names chronicle-demo
   
   # Check image exists
   aws ecr list-images --repository-name chronicle-demo
   ```

### Debug Commands

```bash
# Get ECS service events
aws ecs describe-services \
  --cluster chronicle-demo-cluster \
  --services chronicle-demo-service \
  --query 'services[0].events'

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /ecs/chronicle-demo

# View EFS mount targets
aws efs describe-mount-targets \
  --file-system-id $(terraform output -raw efs_file_system_id)
```

## 💰 Cost Optimization

### Estimated Monthly Costs (us-west-2)

- **ECS Fargate**: ~$30-50/month (2 tasks, 1 vCPU, 2GB RAM)
- **Application Load Balancer**: ~$20/month
- **EFS**: ~$5-10/month (depends on data size)
- **NAT Gateway**: ~$45/month (2 AZs)
- **CloudWatch Logs**: ~$5/month
- **ECR**: ~$1/month

**Total: ~$105-130/month**

### Cost Reduction Tips

1. **Use Fargate Spot** (50-70% savings):
   ```hcl
   # In terraform/ecs.tf
   capacity_providers = ["FARGATE_SPOT"]
   ```

2. **Single AZ Deployment** (save NAT Gateway costs):
   ```hcl
   # In terraform/variables.tf
   public_subnet_cidrs  = ["10.0.1.0/24"]
   private_subnet_cidrs = ["10.0.10.0/24"]
   ```

3. **Reduce Log Retention**:
   ```hcl
   variable "log_retention_days" {
     default = 3  # Instead of 7
   }
   ```

## 🧹 Cleanup

### Destroy Infrastructure

```bash
cd terraform

# Destroy all resources
terraform destroy

# Confirm when prompted
```

### Manual Cleanup (if needed)

```bash
# Delete ECR images
aws ecr batch-delete-image \
  --repository-name chronicle-demo \
  --image-ids imageTag=latest

# Empty and delete S3 buckets (if any)
# Delete CloudWatch log groups
aws logs delete-log-group --log-group-name /ecs/chronicle-demo
```

## 🔐 Security Considerations

### Network Security
- Private subnets for ECS tasks
- Security groups with minimal required access
- ALB in public subnets only

### Data Security
- EFS encryption at rest and in transit
- ECR image scanning enabled
- IAM roles with least privilege

### Monitoring
- CloudWatch container insights enabled
- Application and infrastructure logs centralized
- Auto scaling based on metrics

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Chronicle Map Documentation](https://github.com/OpenHFT/Chronicle-Map)
- [Chronicle Queue Documentation](https://github.com/OpenHFT/Chronicle-Queue)

## 🆘 Support

For issues with:
- **AWS Infrastructure**: Check CloudFormation events and CloudWatch logs
- **Application**: Review ECS task logs and health check endpoints
- **Terraform**: Validate configuration and check state file

---

**Note**: This deployment is configured for development/testing. For production use, consider additional security hardening, monitoring, and backup strategies.