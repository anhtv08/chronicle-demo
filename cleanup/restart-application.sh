#!/bin/bash

# Chronicle Demo - Restart Application Script
# This script restarts the scaled-down application
set -e

# Configuration
PROJECT_NAME="chronicle-demo"
AWS_REGION="${AWS_REGION:-us-west-2}"
DEFAULT_TASK_COUNT=2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Chronicle Demo - Restart Application${NC}"
echo -e "${BLUE}=====================================${NC}"

# Parse command line arguments
DESIRED_COUNT=${1:-$DEFAULT_TASK_COUNT}

if ! [[ "$DESIRED_COUNT" =~ ^[0-9]+$ ]] || [ "$DESIRED_COUNT" -lt 1 ] || [ "$DESIRED_COUNT" -gt 10 ]; then
    echo -e "${RED}❌ Invalid task count. Please specify a number between 1 and 10.${NC}"
    echo -e "${YELLOW}Usage: $0 [task_count]${NC}"
    echo -e "${YELLOW}Example: $0 3  # Start 3 tasks${NC}"
    exit 1
fi

echo -e "${YELLOW}🎯 Target: ${DESIRED_COUNT} running tasks${NC}"
echo ""

# Function to check if ECS service exists
check_ecs_service() {
    if ! aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION} &>/dev/null; then
        echo -e "${RED}❌ ECS service not found. Please deploy the infrastructure first.${NC}"
        echo -e "${YELLOW}💡 Run: ./deploy-to-aws.sh${NC}"
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
    
    if [ "$desired_count" -eq "$DESIRED_COUNT" ] && [ "$running_count" -eq "$DESIRED_COUNT" ]; then
        echo -e "${GREEN}✅ Service is already running with ${DESIRED_COUNT} tasks${NC}"
        echo -e "${GREEN}🎉 No action needed!${NC}"
        exit 0
    fi
}

# Function to scale up service
scale_up_service() {
    echo -e "${YELLOW}📈 Scaling ECS service to ${DESIRED_COUNT} tasks...${NC}"
    
    aws ecs update-service \
        --cluster ${PROJECT_NAME}-cluster \
        --service ${PROJECT_NAME}-service \
        --desired-count ${DESIRED_COUNT} \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Scale up command sent successfully${NC}"
    else
        echo -e "${RED}❌ Failed to scale up service${NC}"
        exit 1
    fi
}

# Function to wait for scale up
wait_for_scale_up() {
    echo -e "${YELLOW}⏳ Waiting for tasks to start and become healthy...${NC}"
    echo -e "${BLUE}   This typically takes 2-5 minutes${NC}"
    
    # Wait for service to stabilize
    aws ecs wait services-stable \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ All tasks are running and healthy${NC}"
    else
        echo -e "${YELLOW}⚠️  Wait timed out, but scale up may still be in progress${NC}"
    fi
}

# Function to verify scale up
verify_scale_up() {
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
    
    echo -e "${BLUE}📊 Final Status:${NC}"
    echo -e "   Running Tasks: ${running_count}"
    echo -e "   Desired Tasks: ${desired_count}"
    
    if [ "$running_count" -eq "$DESIRED_COUNT" ]; then
        echo -e "${GREEN}✅ Successfully scaled up to ${DESIRED_COUNT} tasks${NC}"
    else
        echo -e "${YELLOW}⚠️  ${running_count}/${DESIRED_COUNT} tasks running (may take a few more minutes)${NC}"
    fi
}

# Function to get application URL
get_application_url() {
    if [ -f "terraform/terraform.tfstate" ]; then
        cd terraform
        local app_url=$(terraform output -raw load_balancer_url 2>/dev/null || echo "")
        cd ..
        
        if [ -n "$app_url" ]; then
            echo -e "${BLUE}🌐 Application URL: ${app_url}${NC}"
            return
        fi
    fi
    
    # Fallback: get ALB DNS name directly
    local alb_dns=$(aws elbv2 describe-load-balancers \
        --names ${PROJECT_NAME}-alb \
        --query 'LoadBalancers[0].DNSName' \
        --output text \
        --region ${AWS_REGION} 2>/dev/null || echo "")
    
    if [ -n "$alb_dns" ] && [ "$alb_dns" != "None" ]; then
        echo -e "${BLUE}🌐 Application URL: http://${alb_dns}${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not retrieve application URL${NC}"
    fi
}

# Function to show cost impact
show_cost_impact() {
    local monthly_cost=$((DESIRED_COUNT * 25))  # Rough estimate: $25/month per task
    
    echo ""
    echo -e "${BLUE}💰 Cost Impact:${NC}"
    echo -e "${BLUE}===============${NC}"
    echo -e "${YELLOW}📈 ECS Fargate costs resumed: ~$${monthly_cost}/month${NC}"
    echo -e "   (${DESIRED_COUNT} tasks × ~$25/month each)"
    echo ""
    echo -e "${BLUE}💡 To minimize costs again:${NC}"
    echo -e "   ./cleanup/cleanup-scale-down.sh"
    echo ""
}

# Function to show monitoring commands
show_monitoring_commands() {
    echo -e "${BLUE}📊 Monitoring Commands:${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    echo -e "${GREEN}Check Service Status:${NC}"
    echo -e "   aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION}"
    echo ""
    echo -e "${GREEN}View Application Logs:${NC}"
    echo -e "   aws logs tail /ecs/${PROJECT_NAME} --follow --region ${AWS_REGION}"
    echo ""
    echo -e "${GREEN}Check Target Health:${NC}"
    echo -e "   aws elbv2 describe-target-health --target-group-arn \$(aws elbv2 describe-target-groups --names ${PROJECT_NAME}-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region ${AWS_REGION}) --region ${AWS_REGION}"
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
    
    # Execute restart
    check_ecs_service
    get_service_status
    scale_up_service
    wait_for_scale_up
    verify_scale_up
    get_application_url
    show_cost_impact
    show_monitoring_commands
    
    echo -e "${GREEN}🎉 Application restart completed successfully!${NC}"
    echo -e "${GREEN}🚀 Chronicle Demo is now running with ${DESIRED_COUNT} tasks${NC}"
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Restart interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"