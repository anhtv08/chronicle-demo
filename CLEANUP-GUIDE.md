# Chronicle Demo - AWS Cleanup Guide

This guide provides comprehensive options for cleaning up AWS resources to minimize or eliminate costs for the Chronicle Demo project.

## 🎯 Cleanup Options Overview

| Script | Cost Reduction | Infrastructure | Data Loss | Restart Time |
|--------|---------------|----------------|-----------|--------------|
| `cleanup-scale-down.sh` | ~$30-50/month | ✅ Kept | ❌ No | 2-5 minutes |
| `cleanup-all.sh` | ~$105-130/month | ❌ Destroyed | ✅ Yes | 10-15 minutes |

## 🔧 Cleanup Scripts

### 1. Scale Down to Zero (`cleanup-scale-down.sh`)
**Best for: Temporary cost reduction while keeping infrastructure**

```bash
./cleanup/cleanup-scale-down.sh
```

**What it does:**
- ✅ Scales ECS service to 0 tasks
- ✅ Keeps all infrastructure intact
- ✅ Preserves all data and configuration
- ✅ Allows quick restart

**Cost Impact:**
- 💰 **Saves**: ~$30-50/month (ECS Fargate costs)
- 💸 **Keeps**: ~$75-80/month (Infrastructure costs)
- 📊 **Total Monthly Cost**: ~$75-80 (down from ~$105-130)

**When to use:**
- Testing project on pause
- Weekend/holiday cost savings
- Temporary resource conservation
- Quick restart needed later

### 2. Complete Cleanup (`cleanup-all.sh`)
**Best for: Permanent removal and zero costs**

```bash
./cleanup/cleanup-all.sh
```

**What it does:**
- 🔥 Destroys ALL AWS resources
- 🗑️ Deletes all data permanently
- 🧹 Cleans up local Terraform state
- 💰 Reduces costs to $0

**Cost Impact:**
- 💰 **Saves**: ~$105-130/month (Everything)
- 💸 **Keeps**: $0/month
- 📊 **Total Monthly Cost**: $0

**When to use:**
- Project completed
- No longer needed
- Maximum cost savings required
- Permanent cleanup

## 🚀 Restart Options

### Quick Restart (After Scale Down)
```bash
./cleanup/restart-application.sh [task_count]
```

**Examples:**
```bash
./cleanup/restart-application.sh     # Start 2 tasks (default)
./cleanup/restart-application.sh 1   # Start 1 task (minimum cost)
./cleanup/restart-application.sh 3   # Start 3 tasks (higher performance)
```

### Full Redeploy (After Complete Cleanup)
```bash
./deploy-to-aws.sh
```

## 💰 Cost Breakdown

### Monthly AWS Costs by Component

| Component | Cost/Month | Scale Down | Complete Cleanup |
|-----------|------------|------------|------------------|
| ECS Fargate (2 tasks) | $30-50 | ❌ $0 | ❌ $0 |
| Application Load Balancer | $20 | ✅ $20 | ❌ $0 |
| NAT Gateway (2 AZs) | $45 | ✅ $45 | ❌ $0 |
| EFS Storage | $5-10 | ✅ $5-10 | ❌ $0 |
| CloudWatch Logs | $5 | ✅ $5 | ❌ $0 |
| ECR Storage | $1 | ✅ $1 | ❌ $0 |
| **Total** | **$105-130** | **$75-80** | **$0** |

### Cost Optimization Tips

1. **Fargate Spot** (50-70% savings on compute):
   ```hcl
   # In terraform/ecs.tf
   capacity_providers = ["FARGATE_SPOT"]
   ```

2. **Single AZ Deployment** (save $22.50/month):
   ```hcl
   # In terraform/variables.tf
   public_subnet_cidrs  = ["10.0.1.0/24"]
   private_subnet_cidrs = ["10.0.10.0/24"]
   ```

3. **Reduced Log Retention**:
   ```hcl
   variable "log_retention_days" {
     default = 3  # Instead of 7
   }
   ```

## 📋 Step-by-Step Cleanup Instructions

### Scenario 1: Temporary Pause (Scale Down)

1. **Scale down the application:**
   ```bash
   ./cleanup/cleanup-scale-down.sh
   ```

2. **Verify cost reduction:**
   - ECS tasks: 0 running
   - Monthly savings: ~$30-50
   - Infrastructure: Intact

3. **Restart when needed:**
   ```bash
   ./cleanup/restart-application.sh
   ```

### Scenario 2: Complete Project Cleanup

1. **Backup any important data** (if needed):
   ```bash
   # Download Chronicle data files (optional)
   aws efs describe-file-systems --query 'FileSystems[?Name==`chronicle-demo-efs`]'
   ```

2. **Run complete cleanup:**
   ```bash
   ./cleanup/cleanup-all.sh
   ```

3. **Verify zero costs:**
   - All resources: Deleted
   - Monthly cost: $0
   - Data: Permanently lost

## 🔍 Verification Commands

### Check Current Costs
```bash
# List all resources with chronicle-demo tag
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=chronicle-demo \
  --region us-west-2

# Check ECS service status
aws ecs describe-services \
  --cluster chronicle-demo-cluster \
  --services chronicle-demo-service \
  --region us-west-2
```

### Monitor Cleanup Progress
```bash
# Check if VPC still exists
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=chronicle-demo-vpc" \
  --region us-west-2

# Check if ECR repository exists
aws ecr describe-repositories \
  --repository-names chronicle-demo \
  --region us-west-2
```

## ⚠️ Important Warnings

### Before Scale Down
- ✅ Application will be temporarily unavailable
- ✅ Data is preserved in EFS
- ✅ Quick restart possible (2-5 minutes)
- ✅ Infrastructure costs continue

### Before Complete Cleanup
- ❌ **ALL DATA WILL BE PERMANENTLY LOST**
- ❌ **CANNOT BE UNDONE**
- ❌ Full redeployment required (10-15 minutes)
- ✅ Costs reduced to $0

## 🆘 Troubleshooting

### Cleanup Fails
```bash
# Check Terraform state
cd terraform
terraform state list

# Force destroy specific resources
terraform destroy -target=aws_ecs_service.chronicle_service

# Manual cleanup
aws ecs delete-service --cluster chronicle-demo-cluster --service chronicle-demo-service --force
```

### Partial Cleanup
```bash
# List remaining resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=chronicle-demo

# Delete specific resource types
aws logs delete-log-group --log-group-name /ecs/chronicle-demo
aws ecr delete-repository --repository-name chronicle-demo --force
```

### Cost Verification
```bash
# Check AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## 📊 Cleanup Decision Matrix

| Situation | Recommended Action | Cost Impact | Restart Time |
|-----------|-------------------|-------------|--------------|
| Weekend break | Scale Down | Save $30-50/month | 2-5 minutes |
| 1-week pause | Scale Down | Save $30-50/month | 2-5 minutes |
| 1-month pause | Complete Cleanup | Save $105-130/month | 10-15 minutes |
| Project done | Complete Cleanup | Save $105-130/month | N/A |
| Demo tomorrow | Scale Down | Save $30-50/month | 2-5 minutes |
| Budget tight | Complete Cleanup | Save $105-130/month | 10-15 minutes |

## 🎯 Quick Reference

### Emergency Cost Stop
```bash
# Fastest way to stop all costs
./cleanup/cleanup-all.sh
```

### Minimal Cost Mode
```bash
# Keep infrastructure, stop compute
./cleanup/cleanup-scale-down.sh
```

### Quick Restart
```bash
# Restart with 1 task (minimum cost)
./cleanup/restart-application.sh 1
```

### Full Redeploy
```bash
# Complete redeployment
./deploy-to-aws.sh
```

---

**💡 Pro Tip**: For testing projects, use scale-down during off-hours and complete cleanup when done to minimize AWS costs while maintaining flexibility.