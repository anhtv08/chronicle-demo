#!/bin/bash

# Chronicle Demo - Scale Down to Zero (Keep Infrastructure)
# This script scales the application to 0 instances to minimize costs while keeping infrastructure
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

echo -e "${BLUE}📉 Chronicle Demo - Scale Down to Zero${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${YELLOW}This will scale your application to 0 instances to minimize costs${NC}"
echo -e "${YELLOW}while keeping all infrastructure intact for quick restart.${NC}"
echo ""

# Function to check if ECS service exists
check_ecs_service() {
    if ! aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION} &>/dev/null; then
        echo -e "${RED}❌ ECS service not found. Nothing to scale down.${NC}"
        exit 1
    fi
}

# Function to get current service status
get_service_status() {
    local running_count=$(aws ecs describe-services \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --query 'services[0].runningCount' \
        --output text \
        --region ${AWS_REGION})
    
    local desired_count=$(aws ecs describe-services \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --query 'services[0].desiredCount' \
        --output text \
        --region ${AWS_REGION})
    
    echo -e "${BLUE}📊 Current Service Status:${NC}"
    echo -e "   Running Tasks: ${running_count}"
    echo -e "   Desired Tasks: ${desired_count}"
    echo ""
    
    if [ "$desired_count" -eq 0 ]; then
        echo -e "${GREEN}✅ Service is already scaled down to 0${NC}"
        echo -e "${GREEN}💰 You're already saving maximum costs!${NC}"
        exit 0
    fi
}

# Function to scale down service
scale_down_service() {
    echo -e "${YELLOW}📉 Scaling ECS service to 0 tasks...${NC}"
    
    aws ecs update-service \
        --cluster ${PROJECT_NAME}-cluster \
        --service ${PROJECT_NAME}-service \
        --desired-count 0 \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Scale down command sent successfully${NC}"
    else
        echo -e "${RED}❌ Failed to scale down service${NC}"
        exit 1
    fi
}

# Function to wait for scale down
wait_for_scale_down() {
    echo -e "${YELLOW}⏳ Waiting for tasks to stop...${NC}"
    
    # Wait for service to stabilize
    aws ecs wait services-stable \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ All tasks have been stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  Wait timed out, but scale down may still be in progress${NC}"
    fi
}

# Function to verify scale down
verify_scale_down() {
    local running_count=$(aws ecs describe-services \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --query 'services[0].runningCount' \
        --output text \
        --region ${AWS_REGION})
    
    echo -e "${BLUE}📊 Final Status:${NC}"
    echo -e "   Running Tasks: ${running_count}"
    
    if [ "$running_count" -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully scaled down to 0 tasks${NC}"
    else
        echo -e "${YELLOW}⚠️  ${running_count} tasks still running (may take a few more minutes)${NC}"
    fi
}

# Function to calculate cost savings
show_cost_savings() {
    echo ""
    echo -e "${BLUE}💰 Cost Savings Summary:${NC}"
    echo -e "${BLUE}========================${NC}"
    echo -e "${GREEN}✅ ECS Fargate costs: Reduced to $0/month${NC}"
    echo -e "${YELLOW}⚠️  Infrastructure costs remain:${NC}"
    echo -e "   • Application Load Balancer: ~$20/month"
    echo -e "   • NAT Gateway: ~$45/month"
    echo -e "   • EFS: ~$5-10/month"
    echo -e "   • CloudWatch Logs: ~$5/month"
    echo ""
    echo -e "${BLUE}💡 Total Monthly Savings: ~$30-50 (ECS Fargate costs)${NC}"
    echo -e "${BLUE}💡 Remaining Monthly Costs: ~$75-80 (Infrastructure)${NC}"
    echo ""
}

# Function to show restart instructions
show_restart_instructions() {
    echo -e "${BLUE}🔄 To Restart the Application:${NC}"
    echo -e "${BLUE}=============================${NC}"
    echo ""
    echo -e "${GREEN}Quick Restart (2 tasks):${NC}"
    echo -e "   aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --desired-count 2 --region ${AWS_REGION}"
    echo ""
    echo -e "${GREEN}Scale to Different Size:${NC}"
    echo -e "   aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --desired-count 1 --region ${AWS_REGION}  # 1 task"
    echo -e "   aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --desired-count 3 --region ${AWS_REGION}  # 3 tasks"
    echo ""
    echo -e "${GREEN}Using Convenience Script:${NC}"
    echo -e "   ./cleanup/restart-application.sh"
    echo ""
    echo -e "${YELLOW}📋 Monitor Restart:${NC}"
    echo -e "   aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION}"
    echo ""
}

# Main execution
main() {
    # Check prerequisites
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        exit 1
    fi
    
    # Execute scale down
    check_ecs_service
    get_service_status
    scale_down_service
    wait_for_scale_down
    verify_scale_down
    show_cost_savings
    show_restart_instructions
    
    echo -e "${GREEN}🎉 Scale down completed successfully!${NC}"
    echo -e "${GREEN}💰 You're now saving ~$30-50/month on compute costs${NC}"
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Scale down interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"