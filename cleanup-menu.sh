#!/bin/bash

# Chronicle Demo - Interactive Cleanup Menu
set -e

# Configuration
PROJECT_NAME="chronicle-demo"
AWS_REGION="${AWS_REGION:-us-west-2}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║            🧹 CHRONICLE DEMO CLEANUP MENU 🧹                  ║"
echo "║                                                              ║"
echo "║              Choose Your Cost Management Option              ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to check current status
check_current_status() {
    echo -e "${BLUE}📊 Current Status Check${NC}"
    echo -e "${BLUE}======================${NC}"
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        echo -e "${YELLOW}Please run 'aws configure' first${NC}"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✅ AWS Account: ${account_id}${NC}"
    echo -e "${GREEN}✅ Region: ${AWS_REGION}${NC}"
    
    # Check ECS service status
    if aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION} &>/dev/null; then
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
        
        echo -e "${BLUE}🚀 ECS Service: Active (${running_count}/${desired_count} tasks)${NC}"
        
        if [ "$running_count" -gt 0 ]; then
            echo -e "${YELLOW}💰 Current compute costs: ~$$(($running_count * 25))/month${NC}"
        else
            echo -e "${GREEN}💰 Current compute costs: $0/month (scaled down)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  ECS Service: Not found${NC}"
    fi
    
    # Check if infrastructure exists
    local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION} 2>/dev/null || echo "None")
    if [ "$vpc_id" != "None" ] && [ "$vpc_id" != "" ]; then
        echo -e "${BLUE}🏗️  Infrastructure: Deployed${NC}"
        echo -e "${YELLOW}💰 Infrastructure costs: ~$75-80/month${NC}"
    else
        echo -e "${GREEN}🏗️  Infrastructure: Not deployed${NC}"
        echo -e "${GREEN}💰 Infrastructure costs: $0/month${NC}"
    fi
    
    echo ""
}

# Function to show cleanup options
show_cleanup_options() {
    echo -e "${CYAN}🎯 Cleanup Options${NC}"
    echo -e "${CYAN}=================${NC}"
    echo ""
    echo -e "${GREEN}1. Scale Down to Zero${NC} (Temporary cost reduction)"
    echo -e "   💰 Saves: ~$30-50/month (compute costs)"
    echo -e "   🏗️  Keeps: Infrastructure intact"
    echo -e "   📊 Data: Preserved"
    echo -e "   🔄 Restart: 2-5 minutes"
    echo ""
    echo -e "${RED}2. Complete Cleanup${NC} (Maximum cost reduction)"
    echo -e "   💰 Saves: ~$105-130/month (everything)"
    echo -e "   🏗️  Removes: All infrastructure"
    echo -e "   📊 Data: ⚠️  PERMANENTLY DELETED"
    echo -e "   🔄 Redeploy: 10-15 minutes"
    echo ""
    echo -e "${BLUE}3. Restart Application${NC} (Resume from scale-down)"
    echo -e "   💰 Costs: Resume compute charges"
    echo -e "   🏗️  Uses: Existing infrastructure"
    echo -e "   📊 Data: Preserved"
    echo -e "   🔄 Time: 2-5 minutes"
    echo ""
    echo -e "${YELLOW}4. Check Status Only${NC} (No changes)"
    echo -e "   📊 Shows: Current resource status"
    echo -e "   💰 Shows: Current cost estimates"
    echo -e "   🔍 Shows: Detailed resource inventory"
    echo ""
    echo -e "${PURPLE}5. Exit${NC} (No action)"
    echo ""
}

# Function to handle scale down
handle_scale_down() {
    echo -e "${YELLOW}📉 Scaling Down to Zero${NC}"
    echo -e "${YELLOW}======================${NC}"
    echo ""
    echo -e "${BLUE}This will:${NC}"
    echo -e "   • Stop all running ECS tasks"
    echo -e "   • Keep all infrastructure"
    echo -e "   • Preserve all data"
    echo -e "   • Save ~$30-50/month"
    echo ""
    read -p "$(echo -e ${YELLOW}Continue with scale down? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./cleanup/cleanup-scale-down.sh
    else
        echo -e "${YELLOW}Scale down cancelled${NC}"
    fi
}

# Function to handle complete cleanup
handle_complete_cleanup() {
    echo -e "${RED}🔥 Complete Cleanup${NC}"
    echo -e "${RED}==================${NC}"
    echo ""
    echo -e "${RED}⚠️  DANGER: This will permanently delete:${NC}"
    echo -e "   • All Chronicle Demo infrastructure"
    echo -e "   • All application data"
    echo -e "   • All logs and metrics"
    echo -e "   • All Docker images"
    echo ""
    echo -e "${GREEN}✅ Benefits:${NC}"
    echo -e "   • AWS costs reduced to $0"
    echo -e "   • Complete resource cleanup"
    echo -e "   • No ongoing charges"
    echo ""
    read -p "$(echo -e ${RED}Are you sure you want to proceed? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./cleanup/cleanup-all.sh
    else
        echo -e "${YELLOW}Complete cleanup cancelled${NC}"
    fi
}

# Function to handle restart
handle_restart() {
    echo -e "${GREEN}🚀 Restart Application${NC}"
    echo -e "${GREEN}=====================${NC}"
    echo ""
    echo -e "${BLUE}Choose number of tasks to start:${NC}"
    echo -e "   1. 1 task  (~$25/month) - Minimum cost"
    echo -e "   2. 2 tasks (~$50/month) - Recommended"
    echo -e "   3. 3 tasks (~$75/month) - Higher performance"
    echo -e "   4. Custom number"
    echo ""
    read -p "$(echo -e ${BLUE}Select option [1-4]: ${NC})" -n 1 -r
    echo
    
    case $REPLY in
        1)
            ./cleanup/restart-application.sh 1
            ;;
        2)
            ./cleanup/restart-application.sh 2
            ;;
        3)
            ./cleanup/restart-application.sh 3
            ;;
        4)
            read -p "$(echo -e ${BLUE}Enter number of tasks (1-10): ${NC})" task_count
            if [[ "$task_count" =~ ^[0-9]+$ ]] && [ "$task_count" -ge 1 ] && [ "$task_count" -le 10 ]; then
                ./cleanup/restart-application.sh $task_count
            else
                echo -e "${RED}Invalid task count. Please enter a number between 1 and 10.${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}Invalid option. Restart cancelled.${NC}"
            ;;
    esac
}

# Function to show detailed status
show_detailed_status() {
    echo -e "${BLUE}📊 Detailed Status Report${NC}"
    echo -e "${BLUE}=========================${NC}"
    echo ""
    
    # ECS Service Details
    if aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION} &>/dev/null; then
        echo -e "${GREEN}🚀 ECS Service Status:${NC}"
        aws ecs describe-services \
            --cluster ${PROJECT_NAME}-cluster \
            --services ${PROJECT_NAME}-service \
            --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}' \
            --output table \
            --region ${AWS_REGION}
        echo ""
    fi
    
    # Load Balancer Status
    if aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region ${AWS_REGION} &>/dev/null; then
        echo -e "${GREEN}⚖️  Load Balancer Status:${NC}"
        local alb_dns=$(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].DNSName' --output text --region ${AWS_REGION})
        echo -e "   URL: http://${alb_dns}"
        echo -e "   State: $(aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --query 'LoadBalancers[0].State.Code' --output text --region ${AWS_REGION})"
        echo ""
    fi
    
    # ECR Repository
    if aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &>/dev/null; then
        echo -e "${GREEN}📦 ECR Repository:${NC}"
        local image_count=$(aws ecr list-images --repository-name ${PROJECT_NAME} --query 'length(imageIds)' --output text --region ${AWS_REGION})
        echo -e "   Images: ${image_count}"
        echo ""
    fi
    
    # Cost Estimate
    echo -e "${YELLOW}💰 Estimated Monthly Costs:${NC}"
    local running_tasks=$(aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --query 'services[0].runningCount' --output text --region ${AWS_REGION} 2>/dev/null || echo "0")
    local compute_cost=$((running_tasks * 25))
    local infra_cost=75
    local total_cost=$((compute_cost + infra_cost))
    
    echo -e "   Compute (ECS): $${compute_cost}"
    echo -e "   Infrastructure: $${infra_cost}"
    echo -e "   Total: $${total_cost}"
    echo ""
}

# Main menu loop
main_menu() {
    while true; do
        check_current_status
        show_cleanup_options
        
        read -p "$(echo -e ${CYAN}Select an option [1-5]: ${NC})" -n 1 -r
        echo
        echo ""
        
        case $REPLY in
            1)
                handle_scale_down
                ;;
            2)
                handle_complete_cleanup
                ;;
            3)
                handle_restart
                ;;
            4)
                show_detailed_status
                ;;
            5)
                echo -e "${GREEN}👋 Goodbye! No changes made.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please select 1-5.${NC}"
                ;;
        esac
        
        echo ""
        read -p "$(echo -e ${BLUE}Press Enter to return to main menu...${NC})"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
    done
}

# Main execution
main() {
    # Make sure we're in the right directory
    if [ ! -f "pom.xml" ] || [ ! -d "terraform" ]; then
        echo -e "${RED}❌ Please run this script from the chronicle-demo root directory${NC}"
        exit 1
    fi
    
    # Make cleanup scripts executable
    chmod +x cleanup/*.sh
    
    # Start main menu
    main_menu
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}👋 Cleanup menu exited${NC}"; exit 0' INT

# Run main function
main "$@"