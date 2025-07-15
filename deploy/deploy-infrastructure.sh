#!/bin/bash

# Chronicle Demo - Deploy Infrastructure Script
set -e

# Configuration
PROJECT_NAME="chronicle-demo"
AWS_REGION="${AWS_REGION:-us-west-2}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗️  Chronicle Demo - Infrastructure Deployment${NC}"
echo -e "${BLUE}=============================================${NC}"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo -e "${YELLOW}📋 Deployment Configuration:${NC}"
echo -e "   Project: ${PROJECT_NAME}"
echo -e "   Environment: ${ENVIRONMENT}"
echo -e "   Region: ${AWS_REGION}"
echo ""

# Navigate to terraform directory
cd terraform

# Step 1: Initialize Terraform
echo -e "${BLUE}🔧 Step 1: Initializing Terraform...${NC}"
terraform init
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform initialization failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform initialized successfully${NC}"

# Step 2: Validate Terraform configuration
echo -e "${BLUE}✅ Step 2: Validating Terraform configuration...${NC}"
terraform validate
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform configuration is valid${NC}"

# Step 3: Plan the deployment
echo -e "${BLUE}📋 Step 3: Planning the deployment...${NC}"
terraform plan \
    -var="project_name=${PROJECT_NAME}" \
    -var="environment=${ENVIRONMENT}" \
    -var="aws_region=${AWS_REGION}" \
    -out=tfplan
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform planning failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform plan created successfully${NC}"

# Step 4: Ask for confirmation
echo ""
echo -e "${YELLOW}⚠️  Ready to deploy infrastructure. This will create AWS resources that may incur costs.${NC}"
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏹️  Deployment cancelled by user${NC}"
    exit 0
fi

# Step 5: Apply the deployment
echo -e "${BLUE}🚀 Step 5: Applying the deployment...${NC}"
terraform apply tfplan
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform apply failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"

# Step 6: Display outputs
echo ""
echo -e "${BLUE}📊 Step 6: Deployment Summary${NC}"
echo -e "${BLUE}=========================${NC}"
terraform output

# Step 7: Display next steps
echo ""
echo -e "${BLUE}🎉 Infrastructure Deployment Complete!${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${GREEN}✅ AWS infrastructure has been deployed${NC}"
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Build and push Docker image: ./deploy/build-and-push.sh"
echo -e "   2. Wait for ECS service to stabilize (5-10 minutes)"
echo -e "   3. Access the application via the load balancer URL shown above"
echo ""
echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo -e "   Check ECS service: aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service"
echo -e "   View logs: aws logs tail /ecs/${PROJECT_NAME} --follow"
echo -e "   Update service: aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --force-new-deployment"
echo ""
echo -e "${YELLOW}⚠️  Remember to destroy resources when done to avoid charges:${NC}"
echo -e "   terraform destroy"
echo ""