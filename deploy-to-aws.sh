#!/bin/bash

# Chronicle Demo - Complete AWS Deployment Orchestrator
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
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║               🚀 CHRONICLE DEMO AWS DEPLOYMENT 🚀             ║"
echo "║                                                              ║"
echo "║         High-Performance Java Chronicle Map/Queue Demo       ║"
echo "║              Infrastructure as Code Deployment               ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}📋 Deployment Configuration:${NC}"
echo -e "   🏷️  Project: ${PROJECT_NAME}"
echo -e "   🌍 Region: ${AWS_REGION}"
echo -e "   🏗️  Environment: ${ENVIRONMENT}"
echo -e "   📅 Date: $(date)"
echo ""

# Function to print step headers
print_step() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║ $1"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "🔍 STEP 1: CHECKING PREREQUISITES"
    
    local missing_tools=()
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        missing_tools+=("AWS CLI")
    else
        echo -e "${GREEN}✅ AWS CLI found: $(aws --version)${NC}"
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    else
        echo -e "${GREEN}✅ Terraform found: $(terraform version | head -n1)${NC}"
    fi
    
    # Check Docker
    if ! docker info &> /dev/null; then
        missing_tools+=("Docker")
    else
        echo -e "${GREEN}✅ Docker found and running${NC}"
    fi
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        missing_tools+=("Maven")
    else
        echo -e "${GREEN}✅ Maven found: $(mvn -version | head -n1)${NC}"
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        missing_tools+=("AWS Credentials")
    else
        local account_id=$(aws sts get-caller-identity --query Account --output text)
        echo -e "${GREEN}✅ AWS credentials configured (Account: ${account_id})${NC}"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required tools:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo -e "${RED}   - ${tool}${NC}"
        done
        echo ""
        echo -e "${YELLOW}Please install missing tools and try again.${NC}"
        echo -e "${YELLOW}See README-DEPLOYMENT.md for installation instructions.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🎉 All prerequisites satisfied!${NC}"
    echo ""
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_step "🏗️  STEP 2: DEPLOYING AWS INFRASTRUCTURE"
    
    echo -e "${YELLOW}📋 This will create the following AWS resources:${NC}"
    echo -e "   • VPC with public/private subnets"
    echo -e "   • ECS Fargate cluster"
    echo -e "   • Application Load Balancer"
    echo -e "   • EFS file system for data persistence"
    echo -e "   • ECR repository for Docker images"
    echo -e "   • CloudWatch log groups"
    echo -e "   • IAM roles and security groups"
    echo ""
    
    read -p "$(echo -e ${YELLOW}⚠️  This will create AWS resources that incur costs. Continue? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⏹️  Deployment cancelled by user${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}🚀 Starting infrastructure deployment...${NC}"
    ./deploy/deploy-infrastructure.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    else
        echo -e "${RED}❌ Infrastructure deployment failed!${NC}"
        exit 1
    fi
    echo ""
}

# Function to build and push application
build_and_push() {
    print_step "🐳 STEP 3: BUILDING AND PUSHING APPLICATION"
    
    echo -e "${BLUE}🔨 Building Chronicle Demo application...${NC}"
    ./deploy/build-and-push.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Application built and pushed successfully!${NC}"
    else
        echo -e "${RED}❌ Application build/push failed!${NC}"
        exit 1
    fi
    echo ""
}

# Function to wait for deployment
wait_for_deployment() {
    print_step "⏳ STEP 4: WAITING FOR SERVICE DEPLOYMENT"
    
    echo -e "${YELLOW}🕐 Waiting for ECS service to deploy and stabilize...${NC}"
    echo -e "${BLUE}   This typically takes 5-10 minutes for the first deployment${NC}"
    
    # Wait for service to be stable
    aws ecs wait services-stable \
        --cluster ${PROJECT_NAME}-cluster \
        --services ${PROJECT_NAME}-service \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ECS service is stable and running!${NC}"
    else
        echo -e "${YELLOW}⚠️  Service stability check timed out, but deployment may still be in progress${NC}"
    fi
    echo ""
}

# Function to validate deployment
validate_deployment() {
    print_step "🔍 STEP 5: VALIDATING DEPLOYMENT"
    
    echo -e "${BLUE}🧪 Running comprehensive deployment validation...${NC}"
    ./deploy/validate-deployment.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Deployment validation passed!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some validation checks failed, but the application may still be functional${NC}"
    fi
    echo ""
}

# Function to display final summary
display_summary() {
    print_step "🎉 DEPLOYMENT COMPLETE!"
    
    # Get load balancer URL
    local lb_url
    if [ -f "terraform/terraform.tfstate" ]; then
        cd terraform
        lb_url=$(terraform output -raw load_balancer_url 2>/dev/null || echo "Not available")
        cd ..
    else
        lb_url="Check AWS Console"
    fi
    
    echo -e "${GREEN}🚀 Chronicle Demo has been successfully deployed to AWS!${NC}"
    echo ""
    echo -e "${CYAN}📊 Deployment Summary:${NC}"
    echo -e "   🌐 Application URL: ${lb_url}"
    echo -e "   🏗️  Infrastructure: Fully deployed"
    echo -e "   🐳 Container: Built and running"
    echo -e "   📊 Monitoring: CloudWatch logs enabled"
    echo -e "   🔄 Auto Scaling: Configured"
    echo ""
    
    echo -e "${BLUE}🔗 Quick Access Links:${NC}"
    echo -e "   📱 Application: ${lb_url}"
    echo -e "   🖥️  ECS Console: https://${AWS_REGION}.console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/clusters/${PROJECT_NAME}-cluster"
    echo -e "   📋 CloudWatch: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#logsV2:log-groups/log-group/%2Fecs%2F${PROJECT_NAME}"
    echo ""
    
    echo -e "${YELLOW}🛠️  Management Commands:${NC}"
    echo -e "   View logs: aws logs tail /ecs/${PROJECT_NAME} --follow --region ${AWS_REGION}"
    echo -e "   Scale up: aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --desired-count 3 --region ${AWS_REGION}"
    echo -e "   Redeploy: aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --force-new-deployment --region ${AWS_REGION}"
    echo ""
    
    echo -e "${RED}💰 Cost Management:${NC}"
    echo -e "   Estimated monthly cost: ~$105-130 USD"
    echo -e "   To destroy resources: cd terraform && terraform destroy"
    echo ""
    
    echo -e "${PURPLE}🎊 Thank you for using Chronicle Demo on AWS! 🎊${NC}"
}

# Main execution flow
main() {
    # Make sure we're in the right directory
    if [ ! -f "pom.xml" ] || [ ! -d "terraform" ]; then
        echo -e "${RED}❌ Please run this script from the chronicle-demo root directory${NC}"
        exit 1
    fi
    
    # Make deployment scripts executable
    chmod +x deploy/*.sh
    
    # Execute deployment steps
    check_prerequisites
    deploy_infrastructure
    build_and_push
    wait_for_deployment
    validate_deployment
    display_summary
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Deployment interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"