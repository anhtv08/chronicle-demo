#!/bin/bash

# Chronicle Demo - Build and Push to ECR Script
set -e

# Configuration
PROJECT_NAME="chronicle-demo"
AWS_REGION="${AWS_REGION:-us-west-2}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Chronicle Demo - AWS Deployment Script${NC}"
echo -e "${BLUE}==========================================${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
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
echo -e "   Region: ${AWS_REGION}"
echo -e "   Account: ${AWS_ACCOUNT_ID}"
echo -e "   ECR Repository: ${ECR_REPOSITORY}"
echo ""

# Step 1: Build the application
echo -e "${BLUE}🔨 Step 1: Building the application...${NC}"
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Maven build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Application built successfully${NC}"

# Step 2: Build Docker image
echo -e "${BLUE}🐳 Step 2: Building Docker image...${NC}"
docker build -t ${PROJECT_NAME}:latest .
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker image built successfully${NC}"

# Step 3: Create ECR repository if it doesn't exist
echo -e "${BLUE}📦 Step 3: Checking ECR repository...${NC}"
aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  ECR repository doesn't exist. Creating...${NC}"
    aws ecr create-repository --repository-name ${PROJECT_NAME} --region ${AWS_REGION}
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create ECR repository${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ ECR repository created${NC}"
else
    echo -e "${GREEN}✅ ECR repository exists${NC}"
fi

# Step 4: Login to ECR
echo -e "${BLUE}🔐 Step 4: Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR login failed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Successfully logged in to ECR${NC}"

# Step 5: Tag and push image
echo -e "${BLUE}🏷️  Step 5: Tagging and pushing image...${NC}"
docker tag ${PROJECT_NAME}:latest ${ECR_REPOSITORY}:latest
docker tag ${PROJECT_NAME}:latest ${ECR_REPOSITORY}:$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}📤 Pushing latest tag...${NC}"
docker push ${ECR_REPOSITORY}:latest
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push latest tag${NC}"
    exit 1
fi

echo -e "${YELLOW}📤 Pushing timestamped tag...${NC}"
docker push ${ECR_REPOSITORY}:$(date +%Y%m%d-%H%M%S)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push timestamped tag${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Images pushed successfully${NC}"

# Step 6: Display next steps
echo ""
echo -e "${BLUE}🎉 Build and Push Complete!${NC}"
echo -e "${BLUE}=========================${NC}"
echo -e "${GREEN}✅ Docker image built and pushed to ECR${NC}"
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Deploy infrastructure: cd terraform && terraform apply"
echo -e "   2. Update ECS service: aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --force-new-deployment"
echo -e "   3. Monitor deployment: aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service"
echo ""
echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo -e "   ECR Repository: ${ECR_REPOSITORY}"
echo -e "   View logs: aws logs tail /ecs/${PROJECT_NAME} --follow"
echo -e "   ECS Console: https://${AWS_REGION}.console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/${PROJECT_NAME}-cluster/services"
echo ""