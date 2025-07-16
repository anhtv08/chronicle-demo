#!/bin/bash

# Chronicle Demo - Local Helm Deployment Cleanup Script
set -e

# Configuration
CHART_NAME="chronicle-demo"
RELEASE_NAME="chronicle-demo-local"
NAMESPACE="default"
IMAGE_NAME="chronicle-demo"

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
echo "║            🧹 CHRONICLE DEMO LOCAL CLEANUP 🧹                 ║"
echo "║                                                              ║"
echo "║                  Helm Chart Cleanup                          ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

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
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}❌ Helm not found${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Helm found: $(helm version --short)${NC}"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl not found${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ kubectl found${NC}"
    fi
    
    # Check Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Kubernetes cluster not accessible${NC}"
        exit 1
    else
        local cluster_info=$(kubectl config current-context)
        echo -e "${GREEN}✅ Kubernetes cluster accessible: ${cluster_info}${NC}"
    fi
    
    echo ""
}

# Function to check current deployment status
check_deployment_status() {
    print_step "📊 STEP 2: CHECKING CURRENT DEPLOYMENT STATUS"
    
    # Check if Helm release exists
    if helm list -n ${NAMESPACE} | grep -q ${RELEASE_NAME}; then
        echo -e "${YELLOW}📦 Helm Release Found:${NC}"
        helm list -n ${NAMESPACE} | grep ${RELEASE_NAME}
        echo ""
        
        # Show release status
        echo -e "${BLUE}📋 Release Status:${NC}"
        helm status ${RELEASE_NAME} -n ${NAMESPACE} --show-desc
        echo ""
        
        # Show pods
        echo -e "${BLUE}🏃 Running Pods:${NC}"
        kubectl get pods -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || echo "No pods found"
        echo ""
        
        # Show services
        echo -e "${BLUE}🌐 Services:${NC}"
        kubectl get svc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || echo "No services found"
        echo ""
        
        # Show PVCs
        echo -e "${BLUE}💾 Persistent Volume Claims:${NC}"
        kubectl get pvc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || echo "No PVCs found"
        echo ""
        
        return 0
    else
        echo -e "${GREEN}✅ No Helm release found for ${RELEASE_NAME}${NC}"
        return 1
    fi
}

# Function to get user confirmation
get_confirmation() {
    print_step "⚠️  CONFIRMATION REQUIRED"
    
    echo -e "${YELLOW}🗑️  This will remove:${NC}"
    echo -e "   • Helm release: ${RELEASE_NAME}"
    echo -e "   • All Kubernetes resources (pods, services, etc.)"
    echo -e "   • Persistent Volume Claims (if any)"
    echo -e "   • Local Docker images (optional)"
    echo ""
    
    read -p "$(echo -e ${YELLOW}Do you want to proceed with cleanup? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⏹️  Cleanup cancelled by user${NC}"
        exit 0
    fi
    echo ""
}

# Function to uninstall Helm release
uninstall_helm_release() {
    print_step "🗑️  STEP 3: UNINSTALLING HELM RELEASE"
    
    if helm list -n ${NAMESPACE} | grep -q ${RELEASE_NAME}; then
        echo -e "${YELLOW}🔄 Uninstalling Helm release: ${RELEASE_NAME}${NC}"
        
        helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Helm release uninstalled successfully${NC}"
        else
            echo -e "${RED}❌ Failed to uninstall Helm release${NC}"
            echo -e "${YELLOW}⚠️  Continuing with manual cleanup...${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️  No Helm release found to uninstall${NC}"
    fi
    echo ""
}

# Function to clean up remaining Kubernetes resources
cleanup_k8s_resources() {
    print_step "🧹 STEP 4: CLEANING UP REMAINING KUBERNETES RESOURCES"
    
    echo -e "${YELLOW}🔍 Checking for remaining resources...${NC}"
    
    # Clean up pods
    local pods=$(kubectl get pods -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$pods" ]; then
        echo -e "${YELLOW}🗑️  Deleting remaining pods...${NC}"
        kubectl delete pods -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} --force --grace-period=0 2>/dev/null || true
        echo -e "${GREEN}   ✅ Pods cleaned up${NC}"
    else
        echo -e "${GREEN}   ✅ No pods to clean up${NC}"
    fi
    
    # Clean up services
    local services=$(kubectl get svc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$services" ]; then
        echo -e "${YELLOW}🗑️  Deleting remaining services...${NC}"
        kubectl delete svc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || true
        echo -e "${GREEN}   ✅ Services cleaned up${NC}"
    else
        echo -e "${GREEN}   ✅ No services to clean up${NC}"
    fi
    
    # Clean up deployments
    local deployments=$(kubectl get deployment -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$deployments" ]; then
        echo -e "${YELLOW}🗑️  Deleting remaining deployments...${NC}"
        kubectl delete deployment -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || true
        echo -e "${GREEN}   ✅ Deployments cleaned up${NC}"
    else
        echo -e "${GREEN}   ✅ No deployments to clean up${NC}"
    fi
    
    # Clean up configmaps
    local configmaps=$(kubectl get configmap -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$configmaps" ]; then
        echo -e "${YELLOW}🗑️  Deleting remaining configmaps...${NC}"
        kubectl delete configmap -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || true
        echo -e "${GREEN}   ✅ ConfigMaps cleaned up${NC}"
    else
        echo -e "${GREEN}   ✅ No configmaps to clean up${NC}"
    fi
    
    # Clean up secrets
    local secrets=$(kubectl get secret -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$secrets" ]; then
        echo -e "${YELLOW}🗑️  Deleting remaining secrets...${NC}"
        kubectl delete secret -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || true
        echo -e "${GREEN}   ✅ Secrets cleaned up${NC}"
    else
        echo -e "${GREEN}   ✅ No secrets to clean up${NC}"
    fi
    
    # Clean up service accounts
    local serviceaccounts=$(kubectl get serviceaccount -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$serviceaccounts" ]; then
        echo -e "${YELLOW}🗑️  Deleting remaining service accounts...${NC}"
        kubectl delete serviceaccount -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || true
        echo -e "${GREEN}   ✅ Service accounts cleaned up${NC}"
    else
        echo -e "${GREEN}   ✅ No service accounts to clean up${NC}"
    fi
    
    echo ""
}

# Function to clean up persistent volumes
cleanup_persistent_volumes() {
    print_step "💾 STEP 5: CLEANING UP PERSISTENT VOLUMES"
    
    # Check for PVCs
    local pvcs=$(kubectl get pvc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -o name 2>/dev/null || echo "")
    if [ -n "$pvcs" ]; then
        echo -e "${YELLOW}⚠️  Found Persistent Volume Claims:${NC}"
        kubectl get pvc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE}
        echo ""
        
        read -p "$(echo -e ${YELLOW}Do you want to delete PVCs? This will permanently delete data! [y/N]: ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}🗑️  Deleting Persistent Volume Claims...${NC}"
            kubectl delete pvc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || true
            echo -e "${GREEN}   ✅ PVCs deleted${NC}"
        else
            echo -e "${YELLOW}   ⏭️  PVCs preserved${NC}"
        fi
    else
        echo -e "${GREEN}✅ No Persistent Volume Claims to clean up${NC}"
    fi
    echo ""
}

# Function to clean up Docker images
cleanup_docker_images() {
    print_step "🐳 STEP 6: CLEANING UP DOCKER IMAGES"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker not found, skipping image cleanup${NC}"
        echo ""
        return
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${YELLOW}⚠️  Docker not running, skipping image cleanup${NC}"
        echo ""
        return
    fi
    
    # Check for Chronicle Demo images
    local images=$(docker images ${IMAGE_NAME} --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || echo "")
    if [ -n "$images" ] && [ "$images" != "REPOSITORY:TAG	SIZE	CREATED AT" ]; then
        echo -e "${YELLOW}🐳 Found Chronicle Demo Docker images:${NC}"
        docker images ${IMAGE_NAME} --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        echo ""
        
        read -p "$(echo -e ${YELLOW}Do you want to delete Docker images? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🗑️  Deleting Docker images...${NC}"
            docker rmi $(docker images ${IMAGE_NAME} -q) 2>/dev/null || true
            echo -e "${GREEN}   ✅ Docker images deleted${NC}"
        else
            echo -e "${YELLOW}   ⏭️  Docker images preserved${NC}"
        fi
    else
        echo -e "${GREEN}✅ No Chronicle Demo Docker images found${NC}"
    fi
    
    # Offer to clean up dangling images
    local dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null || echo "")
    if [ -n "$dangling_images" ]; then
        echo ""
        read -p "$(echo -e ${YELLOW}Clean up dangling Docker images? [y/N]: ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}🗑️  Cleaning up dangling images...${NC}"
            docker image prune -f 2>/dev/null || true
            echo -e "${GREEN}   ✅ Dangling images cleaned up${NC}"
        fi
    fi
    echo ""
}

# Function to verify cleanup
verify_cleanup() {
    print_step "✅ STEP 7: VERIFYING CLEANUP"
    
    echo -e "${YELLOW}🔍 Checking for remaining resources...${NC}"
    
    # Check Helm releases
    local helm_releases=$(helm list -n ${NAMESPACE} | grep ${RELEASE_NAME} || echo "")
    if [ -z "$helm_releases" ]; then
        echo -e "${GREEN}   ✅ No Helm releases found${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Helm release still exists:${NC}"
        echo "$helm_releases"
    fi
    
    # Check pods
    local pods=$(kubectl get pods -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || echo "")
    if [ -z "$pods" ]; then
        echo -e "${GREEN}   ✅ No pods found${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Pods still exist${NC}"
    fi
    
    # Check services
    local services=$(kubectl get svc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || echo "")
    if [ -z "$services" ]; then
        echo -e "${GREEN}   ✅ No services found${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Services still exist${NC}"
    fi
    
    # Check PVCs
    local pvcs=$(kubectl get pvc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} 2>/dev/null || echo "")
    if [ -z "$pvcs" ]; then
        echo -e "${GREEN}   ✅ No PVCs found${NC}"
    else
        echo -e "${YELLOW}   ⚠️  PVCs still exist (may be intentional)${NC}"
    fi
    
    echo ""
}

# Function to show cleanup summary
show_cleanup_summary() {
    print_step "🎉 CLEANUP COMPLETE!"
    
    echo -e "${GREEN}🧹 Chronicle Demo local deployment cleanup completed!${NC}"
    echo ""
    echo -e "${BLUE}📊 Cleanup Summary:${NC}"
    echo -e "   • Helm release: Removed"
    echo -e "   • Kubernetes resources: Cleaned up"
    echo -e "   • Docker images: User choice"
    echo -e "   • Persistent data: User choice"
    echo ""
    
    echo -e "${YELLOW}🔧 Useful Commands:${NC}"
    echo -e "   Check remaining resources: kubectl get all -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE}"
    echo -e "   List Helm releases: helm list -n ${NAMESPACE}"
    echo -e "   Redeploy: ./helm/deploy-local.sh"
    echo ""
    
    echo -e "${BLUE}💡 Next Steps:${NC}"
    echo -e "   • To redeploy: Run ./helm/deploy-local.sh"
    echo -e "   • To deploy to OpenShift: Use the OpenShift-specific values"
    echo -e "   • To clean up AWS: Run ./cleanup/cleanup-all.sh"
    echo ""
    
    echo -e "${PURPLE}🎊 Local environment cleaned up successfully! 🎊${NC}"
}

# Main execution flow
main() {
    # Make sure we're in the right directory
    if [ ! -f "pom.xml" ] || [ ! -d "helm/chronicle-demo" ]; then
        echo -e "${RED}❌ Please run this script from the chronicle-demo root directory${NC}"
        exit 1
    fi
    
    # Execute cleanup steps
    check_prerequisites
    
    # Check if there's anything to clean up
    if ! check_deployment_status; then
        echo -e "${GREEN}✅ No Chronicle Demo deployment found to clean up${NC}"
        echo -e "${BLUE}💡 If you want to clean up Docker images anyway, run:${NC}"
        echo -e "   docker rmi chronicle-demo:latest"
        exit 0
    fi
    
    get_confirmation
    uninstall_helm_release
    cleanup_k8s_resources
    cleanup_persistent_volumes
    cleanup_docker_images
    verify_cleanup
    show_cleanup_summary
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Cleanup interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"