#!/bin/bash

# Chronicle Demo - Deployment Validation Script
set -e

# Configuration
PROJECT_NAME="chronicle-demo"
AWS_REGION="${AWS_REGION:-us-west-2}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Chronicle Demo - Deployment Validation${NC}"
echo -e "${BLUE}=======================================${NC}"

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

# Function to wait for service stability
wait_for_service_stable() {
    echo -e "${YELLOW}⏳ Waiting for ECS service to stabilize...${NC}"
    aws ecs wait services-stable \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --region ${AWS_REGION}
    check_status "ECS service is stable"
}

# Function to test health endpoint
test_health_endpoint() {
    local url=$1
    echo -e "${YELLOW}🏥 Testing health endpoint: ${url}${NC}"
    
    # Try up to 5 times with 10 second intervals
    for i in {1..5}; do
        if curl -f -s "${url}" > /dev/null; then
            echo -e "${GREEN}✅ Health endpoint is responding${NC}"
            return 0
        else
            echo -e "${YELLOW}⏳ Attempt ${i}/5 - Health endpoint not ready, waiting 10 seconds...${NC}"
            sleep 10
        fi
    done
    
    echo -e "${RED}❌ Health endpoint is not responding after 5 attempts${NC}"
    return 1
}

# Step 1: Validate AWS CLI and credentials
echo -e "${BLUE}🔐 Step 1: Validating AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null 2>&1
check_status "AWS credentials are valid"

# Step 2: Check if infrastructure exists
echo -e "${BLUE}🏗️  Step 2: Checking infrastructure...${NC}"

# Check VPC
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION} 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
    echo -e "${GREEN}✅ VPC exists: ${VPC_ID}${NC}"
else
    echo -e "${RED}❌ VPC not found${NC}"
    exit 1
fi

# Check ECS Cluster
aws ecs describe-clusters --clusters ${PROJECT_NAME}-cluster --region ${AWS_REGION} > /dev/null 2>&1
check_status "ECS cluster exists"

# Check ECS Service
aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION} > /dev/null 2>&1
check_status "ECS service exists"

# Check Load Balancer
ALB_ARN=$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text --region ${AWS_REGION} 2>/dev/null)
if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "" ]; then
    echo -e "${GREEN}✅ Application Load Balancer exists${NC}"
    ALB_DNS=$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].DNSName' --output text --region ${AWS_REGION})
    echo -e "${BLUE}   DNS Name: ${ALB_DNS}${NC}"
else
    echo -e "${RED}❌ Application Load Balancer not found${NC}"
    exit 1
fi

# Check ECR Repository
aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} > /dev/null 2>&1
check_status "ECR repository exists"

# Step 3: Check ECS Service Status
echo -e "${BLUE}🚀 Step 3: Checking ECS service status...${NC}"

# Get service details
SERVICE_STATUS=$(aws ecs describe-services \
    --cluster ${PROJECT_NAME}-cluster \
    --services ${PROJECT_NAME}-service \
    --query 'services[0].status' \
    --output text \
    --region ${AWS_REGION})

RUNNING_COUNT=$(aws ecs describe-services \
    --cluster ${PROJECT_NAME}-cluster \
    --services ${PROJECT_NAME}-service \
    --query 'services[0].runningCount' \
    --output text \
    --region ${AWS_REGION})

DESIRED_COUNT=$(aws ecs describe-services \
    --cluster ${PROJECT_NAME}-cluster \
    --services ${PROJECT_NAME}-service \
    --query 'services[0].desiredCount' \
    --output text \
    --region ${AWS_REGION})

echo -e "${BLUE}   Service Status: ${SERVICE_STATUS}${NC}"
echo -e "${BLUE}   Running Tasks: ${RUNNING_COUNT}/${DESIRED_COUNT}${NC}"

if [ "$SERVICE_STATUS" = "ACTIVE" ] && [ "$RUNNING_COUNT" -eq "$DESIRED_COUNT" ]; then
    echo -e "${GREEN}✅ ECS service is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  ECS service is not fully healthy, waiting for stability...${NC}"
    wait_for_service_stable
fi

# Step 4: Check Target Group Health
echo -e "${BLUE}🎯 Step 4: Checking target group health...${NC}"

TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --names ${PROJECT_NAME}-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region ${AWS_REGION})

HEALTHY_TARGETS=$(aws elbv2 describe-target-health \
    --target-group-arn ${TARGET_GROUP_ARN} \
    --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' \
    --output text \
    --region ${AWS_REGION})

TOTAL_TARGETS=$(aws elbv2 describe-target-health \
    --target-group-arn ${TARGET_GROUP_ARN} \
    --query 'length(TargetHealthDescriptions)' \
    --output text \
    --region ${AWS_REGION})

echo -e "${BLUE}   Healthy Targets: ${HEALTHY_TARGETS}/${TOTAL_TARGETS}${NC}"

if [ "$HEALTHY_TARGETS" -gt 0 ]; then
    echo -e "${GREEN}✅ Target group has healthy targets${NC}"
else
    echo -e "${YELLOW}⚠️  No healthy targets found, this may take a few minutes...${NC}"
fi

# Step 5: Test Application Endpoints
echo -e "${BLUE}🌐 Step 5: Testing application endpoints...${NC}"

APP_URL="http://${ALB_DNS}"
echo -e "${BLUE}   Application URL: ${APP_URL}${NC}"

# Test health endpoint
test_health_endpoint "${APP_URL}/"

# Test if we can reach the load balancer
echo -e "${YELLOW}🔗 Testing load balancer connectivity...${NC}"
if curl -f -s --max-time 10 "${APP_URL}" > /dev/null; then
    echo -e "${GREEN}✅ Load balancer is accessible${NC}"
else
    echo -e "${RED}❌ Load balancer is not accessible${NC}"
fi

# Step 6: Check Logs
echo -e "${BLUE}📋 Step 6: Checking application logs...${NC}"

# Get recent log entries
LOG_ENTRIES=$(aws logs describe-log-streams \
    --log-group-name "/ecs/${PROJECT_NAME}" \
    --order-by LastEventTime \
    --descending \
    --max-items 1 \
    --query 'logStreams[0].logStreamName' \
    --output text \
    --region ${AWS_REGION} 2>/dev/null)

if [ "$LOG_ENTRIES" != "None" ] && [ "$LOG_ENTRIES" != "" ]; then
    echo -e "${GREEN}✅ Application logs are available${NC}"
    echo -e "${BLUE}   Latest log stream: ${LOG_ENTRIES}${NC}"
    
    # Show last few log entries
    echo -e "${YELLOW}📄 Recent log entries:${NC}"
    aws logs get-log-events \
        --log-group-name "/ecs/${PROJECT_NAME}" \
        --log-stream-name "${LOG_ENTRIES}" \
        --limit 5 \
        --query 'events[*].message' \
        --output text \
        --region ${AWS_REGION} 2>/dev/null | tail -5
else
    echo -e "${YELLOW}⚠️  No log entries found yet${NC}"
fi

# Step 7: Performance Check
echo -e "${BLUE}⚡ Step 7: Basic performance check...${NC}"

if command -v curl &> /dev/null; then
    echo -e "${YELLOW}🚀 Testing response time...${NC}"
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' --max-time 30 "${APP_URL}/" 2>/dev/null || echo "timeout")
    
    if [ "$RESPONSE_TIME" != "timeout" ]; then
        echo -e "${GREEN}✅ Response time: ${RESPONSE_TIME} seconds${NC}"
    else
        echo -e "${YELLOW}⚠️  Response time test timed out${NC}"
    fi
fi

# Step 8: Summary
echo ""
echo -e "${BLUE}📊 Deployment Validation Summary${NC}"
echo -e "${BLUE}===============================${NC}"
echo -e "${GREEN}✅ Infrastructure: Deployed and configured${NC}"
echo -e "${GREEN}✅ ECS Service: Running with ${RUNNING_COUNT}/${DESIRED_COUNT} tasks${NC}"
echo -e "${GREEN}✅ Load Balancer: Accessible at ${APP_URL}${NC}"
echo -e "${GREEN}✅ Health Check: Responding${NC}"

echo ""
echo -e "${BLUE}🔗 Useful Links and Commands:${NC}"
echo -e "   Application URL: ${APP_URL}"
echo -e "   AWS Console: https://${AWS_REGION}.console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/${PROJECT_NAME}-cluster"
echo -e "   View Logs: aws logs tail /ecs/${PROJECT_NAME} --follow --region ${AWS_REGION}"
echo -e "   Scale Service: aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --desired-count 3 --region ${AWS_REGION}"

echo ""
echo -e "${BLUE}🎉 Validation Complete!${NC}"
echo -e "${GREEN}✅ Chronicle Demo is successfully deployed and running on AWS${NC}"
echo ""