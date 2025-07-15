#!/bin/bash

# Chronicle Demo - Complete AWS Cleanup Script
# This script removes ALL AWS resources to reduce costs to ZERO
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
NC='\033[0m' # No Color

# Banner
echo -e "${RED}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║               🧹 CHRONICLE DEMO AWS CLEANUP 🧹                ║"
echo "║                                                              ║"
echo "║              ⚠️  COMPLETE RESOURCE DESTRUCTION ⚠️              ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  WARNING: This will DELETE ALL AWS resources for Chronicle Demo!${NC}"
echo -e "${YELLOW}   This action is IRREVERSIBLE and will result in:${NC}"
echo -e "${RED}   • Complete data loss${NC}"
echo -e "${RED}   • Destruction of all infrastructure${NC}"
echo -e "${RED}   • Immediate cost reduction to $0${NC}"
echo ""

# Function to print step headers
print_step() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║ $1"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to check if resources exist
check_resources() {
    print_step "🔍 STEP 1: CHECKING EXISTING RESOURCES"
    
    local resources_found=false
    
    # Check Terraform state
    if [ -f "terraform/terraform.tfstate" ]; then
        echo -e "${YELLOW}📄 Terraform state file found${NC}"
        resources_found=true
    fi
    
    # Check VPC
    local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION} 2>/dev/null || echo "None")
    if [ "$vpc_id" != "None" ] && [ "$vpc_id" != "" ]; then
        echo -e "${YELLOW}🏗️  VPC found: ${vpc_id}${NC}"
        resources_found=true
    fi
    
    # Check ECS Cluster
    if aws ecs describe-clusters --clusters ${PROJECT_NAME}-cluster --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}🚀 ECS Cluster found${NC}"
        resources_found=true
    fi
    
    # Check ECR Repository
    if aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}📦 ECR Repository found${NC}"
        resources_found=true
    fi
    
    # Check Load Balancer
    if aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}⚖️  Load Balancer found${NC}"
        resources_found=true
    fi
    
    # Check CloudWatch Log Groups
    local log_groups=$(aws logs describe-log-groups --log-group-name-prefix "/ecs/${PROJECT_NAME}" --query 'logGroups[].logGroupName' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
    if [ -n "$log_groups" ]; then
        echo -e "${YELLOW}📋 CloudWatch Log Groups found${NC}"
        resources_found=true
    fi
    
    if [ "$resources_found" = false ]; then
        echo -e "${GREEN}✅ No Chronicle Demo resources found in AWS${NC}"
        echo -e "${GREEN}💰 Your AWS costs are already at $0 for this project${NC}"
        exit 0
    fi
    
    echo -e "${RED}⚠️  Chronicle Demo resources found and will be deleted${NC}"
    echo ""
}

# Function to get final confirmation
get_confirmation() {
    print_step "⚠️  FINAL CONFIRMATION REQUIRED"
    
    echo -e "${RED}🚨 DANGER ZONE 🚨${NC}"
    echo -e "${YELLOW}You are about to permanently delete:${NC}"
    echo -e "   • All Chronicle Demo infrastructure"
    echo -e "   • All application data and logs"
    echo -e "   • All Docker images in ECR"
    echo -e "   • All CloudWatch logs and metrics"
    echo ""
    echo -e "${YELLOW}This action cannot be undone!${NC}"
    echo ""
    
    read -p "$(echo -e ${RED}Type 'DELETE' to confirm complete destruction: ${NC})" confirmation
    if [ "$confirmation" != "DELETE" ]; then
        echo -e "${YELLOW}⏹️  Cleanup cancelled by user${NC}"
        echo -e "${GREEN}💰 Your resources remain active (costs continue)${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${RED}🔥 Proceeding with complete resource destruction...${NC}"
    echo ""
}

# Function to stop ECS service (to speed up cleanup)
stop_ecs_service() {
    print_step "⏹️  STEP 2: STOPPING ECS SERVICE"
    
    if aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}🛑 Scaling ECS service to 0 tasks...${NC}"
        aws ecs update-service \
            --cluster ${PROJECT_NAME}-cluster \
            --service ${PROJECT_NAME}-service \
            --desired-count 0 \
            --region ${AWS_REGION} &>/dev/null
        
        echo -e "${YELLOW}⏳ Waiting for tasks to stop...${NC}"
        aws ecs wait services-stable \
            --cluster ${PROJECT_NAME}-cluster \
            --services ${PROJECT_NAME}-service \
            --region ${AWS_REGION} || true
        
        echo -e "${GREEN}✅ ECS service stopped${NC}"
    else
        echo -e "${BLUE}ℹ️  No ECS service found${NC}"
    fi
    echo ""
}

# Function to clean ECR repository
clean_ecr_repository() {
    print_step "📦 STEP 3: CLEANING ECR REPOSITORY"
    
    if aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}🗑️  Deleting all Docker images...${NC}"
        
        # Get all image tags
        local image_tags=$(aws ecr list-images --repository-name ${PROJECT_NAME} --query 'imageIds[].imageTag' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
        
        if [ -n "$image_tags" ]; then
            # Delete tagged images
            for tag in $image_tags; do
                if [ "$tag" != "None" ]; then
                    aws ecr batch-delete-image \
                        --repository-name ${PROJECT_NAME} \
                        --image-ids imageTag=$tag \
                        --region ${AWS_REGION} &>/dev/null || true
                    echo -e "${GREEN}   ✅ Deleted image: ${tag}${NC}"
                fi
            done
        fi
        
        # Delete untagged images
        local untagged_images=$(aws ecr list-images --repository-name ${PROJECT_NAME} --filter tagStatus=UNTAGGED --query 'imageIds' --output json --region ${AWS_REGION} 2>/dev/null || echo "[]")
        if [ "$untagged_images" != "[]" ] && [ -n "$untagged_images" ]; then
            aws ecr batch-delete-image \
                --repository-name ${PROJECT_NAME} \
                --image-ids "$untagged_images" \
                --region ${AWS_REGION} &>/dev/null || true
            echo -e "${GREEN}   ✅ Deleted untagged images${NC}"
        fi
        
        echo -e "${GREEN}✅ ECR repository cleaned${NC}"
    else
        echo -e "${BLUE}ℹ️  No ECR repository found${NC}"
    fi
    echo ""
}

# Function to destroy Terraform infrastructure
destroy_terraform() {
    print_step "🏗️  STEP 4: DESTROYING TERRAFORM INFRASTRUCTURE"
    
    if [ -f "terraform/terraform.tfstate" ]; then
        echo -e "${YELLOW}🔥 Destroying all Terraform-managed resources...${NC}"
        
        cd terraform
        
        # Initialize Terraform (in case it's not initialized)
        terraform init &>/dev/null || true
        
        # Destroy all resources
        terraform destroy \
            -var="project_name=${PROJECT_NAME}" \
            -var="aws_region=${AWS_REGION}" \
            -auto-approve
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Terraform infrastructure destroyed${NC}"
        else
            echo -e "${RED}❌ Terraform destroy encountered errors${NC}"
            echo -e "${YELLOW}⚠️  Some resources may need manual cleanup${NC}"
        fi
        
        cd ..
    else
        echo -e "${BLUE}ℹ️  No Terraform state found${NC}"
    fi
    echo ""
}

# Function to clean up remaining resources manually
manual_cleanup() {
    print_step "🧹 STEP 5: MANUAL CLEANUP OF REMAINING RESOURCES"
    
    echo -e "${YELLOW}🔍 Checking for any remaining resources...${NC}"
    
    # Clean up CloudWatch Log Groups
    local log_groups=$(aws logs describe-log-groups --log-group-name-prefix "/ecs/${PROJECT_NAME}" --query 'logGroups[].logGroupName' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
    if [ -n "$log_groups" ]; then
        echo -e "${YELLOW}📋 Deleting CloudWatch log groups...${NC}"
        for log_group in $log_groups; do
            aws logs delete-log-group --log-group-name "$log_group" --region ${AWS_REGION} &>/dev/null || true
            echo -e "${GREEN}   ✅ Deleted log group: ${log_group}${NC}"
        done
    fi
    
    # Clean up any remaining ECR repository
    if aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}📦 Deleting ECR repository...${NC}"
        aws ecr delete-repository --repository-name ${PROJECT_NAME} --force --region ${AWS_REGION} &>/dev/null || true
        echo -e "${GREEN}   ✅ ECR repository deleted${NC}"
    fi
    
    # Check for any remaining ECS resources
    if aws ecs describe-clusters --clusters ${PROJECT_NAME}-cluster --region ${AWS_REGION} &>/dev/null; then
        echo -e "${YELLOW}🚀 Deleting ECS cluster...${NC}"
        aws ecs delete-cluster --cluster ${PROJECT_NAME}-cluster --region ${AWS_REGION} &>/dev/null || true
        echo -e "${GREEN}   ✅ ECS cluster deleted${NC}"
    fi
    
    echo -e "${GREEN}✅ Manual cleanup completed${NC}"
    echo ""
}

# Function to clean up local files
clean_local_files() {
    print_step "📁 STEP 6: CLEANING LOCAL FILES"
    
    echo -e "${YELLOW}🗑️  Cleaning up local deployment files...${NC}"
    
    # Remove Terraform state files
    if [ -f "terraform/terraform.tfstate" ]; then
        rm -f terraform/terraform.tfstate
        echo -e "${GREEN}   ✅ Removed terraform.tfstate${NC}"
    fi
    
    if [ -f "terraform/terraform.tfstate.backup" ]; then
        rm -f terraform/terraform.tfstate.backup
        echo -e "${GREEN}   ✅ Removed terraform.tfstate.backup${NC}"
    fi
    
    # Remove Terraform lock file
    if [ -f "terraform/.terraform.lock.hcl" ]; then
        rm -f terraform/.terraform.lock.hcl
        echo -e "${GREEN}   ✅ Removed .terraform.lock.hcl${NC}"
    fi
    
    # Remove Terraform directory
    if [ -d "terraform/.terraform" ]; then
        rm -rf terraform/.terraform
        echo -e "${GREEN}   ✅ Removed .terraform directory${NC}"
    fi
    
    # Remove plan files
    if [ -f "terraform/tfplan" ]; then
        rm -f terraform/tfplan
        echo -e "${GREEN}   ✅ Removed tfplan${NC}"
    fi
    
    echo -e "${GREEN}✅ Local files cleaned${NC}"
    echo ""
}

# Function to verify cleanup
verify_cleanup() {
    print_step "✅ STEP 7: VERIFYING COMPLETE CLEANUP"
    
    echo -e "${YELLOW}🔍 Verifying all resources have been removed...${NC}"
    
    local remaining_resources=()
    
    # Check VPC
    local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text --region ${AWS_REGION} 2>/dev/null || echo "None")
    if [ "$vpc_id" != "None" ] && [ "$vpc_id" != "" ]; then
        remaining_resources+=("VPC: $vpc_id")
    fi
    
    # Check ECS Cluster
    if aws ecs describe-clusters --clusters ${PROJECT_NAME}-cluster --region ${AWS_REGION} &>/dev/null; then
        remaining_resources+=("ECS Cluster")
    fi
    
    # Check ECR Repository
    if aws ecr describe-repositories --repository-names ${PROJECT_NAME} --region ${AWS_REGION} &>/dev/null; then
        remaining_resources+=("ECR Repository")
    fi
    
    # Check Load Balancer
    if aws elbv2 describe-load-balancers --names ${PROJECT_NAME}-alb --region ${AWS_REGION} &>/dev/null; then
        remaining_resources+=("Load Balancer")
    fi
    
    # Check CloudWatch Log Groups
    local log_groups=$(aws logs describe-log-groups --log-group-name-prefix "/ecs/${PROJECT_NAME}" --query 'logGroups[].logGroupName' --output text --region ${AWS_REGION} 2>/dev/null || echo "")
    if [ -n "$log_groups" ]; then
        remaining_resources+=("CloudWatch Log Groups")
    fi
    
    if [ ${#remaining_resources[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 SUCCESS: All Chronicle Demo resources have been completely removed!${NC}"
        echo -e "${GREEN}💰 Your AWS costs for this project are now $0${NC}"
    else
        echo -e "${YELLOW}⚠️  Some resources may still exist:${NC}"
        for resource in "${remaining_resources[@]}"; do
            echo -e "${YELLOW}   - ${resource}${NC}"
        done
        echo -e "${YELLOW}💡 You may need to check the AWS Console for manual cleanup${NC}"
    fi
    echo ""
}

# Function to display final summary
display_summary() {
    print_step "🎊 CLEANUP COMPLETE!"
    
    echo -e "${GREEN}🧹 Chronicle Demo AWS cleanup has been completed!${NC}"
    echo ""
    echo -e "${BLUE}📊 Cleanup Summary:${NC}"
    echo -e "   🏗️  Infrastructure: Destroyed"
    echo -e "   🐳 Containers: Removed from ECR"
    echo -e "   📋 Logs: Deleted from CloudWatch"
    echo -e "   📁 Local Files: Cleaned up"
    echo -e "   💰 AWS Costs: Reduced to $0"
    echo ""
    
    echo -e "${YELLOW}📋 What was removed:${NC}"
    echo -e "   • VPC and all networking components"
    echo -e "   • ECS Fargate cluster and services"
    echo -e "   • Application Load Balancer"
    echo -e "   • EFS file system and mount targets"
    echo -e "   • ECR repository and all images"
    echo -e "   • CloudWatch log groups and streams"
    echo -e "   • IAM roles and security groups"
    echo -e "   • All Terraform state files"
    echo ""
    
    echo -e "${BLUE}🔄 To redeploy Chronicle Demo:${NC}"
    echo -e "   ./deploy-to-aws.sh"
    echo ""
    
    echo -e "${GREEN}💡 Pro Tip: For future testing, consider using:${NC}"
    echo -e "   • ./cleanup/cleanup-keep-infrastructure.sh (keeps VPC, removes apps)"
    echo -e "   • ./cleanup/cleanup-scale-down.sh (scales to 0, keeps everything)"
    echo ""
    
    echo -e "${PURPLE}🎉 Thank you for using Chronicle Demo! 🎉${NC}"
    echo -e "${GREEN}💰 Your AWS bill will reflect $0 costs for this project going forward.${NC}"
}

# Main execution flow
main() {
    # Make sure we're in the right directory
    if [ ! -f "pom.xml" ] || [ ! -d "terraform" ]; then
        echo -e "${RED}❌ Please run this script from the chronicle-demo root directory${NC}"
        exit 1
    fi
    
    # Execute cleanup steps
    check_resources
    get_confirmation
    stop_ecs_service
    clean_ecr_repository
    destroy_terraform
    manual_cleanup
    clean_local_files
    verify_cleanup
    display_summary
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Cleanup interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"