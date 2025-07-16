#!/bin/bash

# Chronicle Demo - Local Helm Deployment Script
set -e

# Configuration
CHART_NAME="chronicle-demo"
RELEASE_NAME="chronicle-demo-local"
NAMESPACE="default"
VALUES_FILE="helm/chronicle-demo/values-local.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║            🚀 CHRONICLE DEMO LOCAL DEPLOYMENT 🚀             ║"
echo "║                                                              ║"
echo "║                  Helm Chart Testing                          ║"
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
    
    local missing_tools=()
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        missing_tools+=("Helm")
    else
        echo -e "${GREEN}✅ Helm found: $(helm version --short)${NC}"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    else
        echo -e "${GREEN}✅ kubectl found: $(kubectl version --client --short 2>/dev/null)${NC}"
    fi
    
    # Check Docker
    if ! docker info &> /dev/null; then
        missing_tools+=("Docker")
    else
        echo -e "${GREEN}✅ Docker found and running${NC}"
    fi
    
    # Check Kubernetes cluster
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Kubernetes cluster not accessible${NC}"
        echo -e "${YELLOW}💡 Make sure you have a local Kubernetes cluster running:${NC}"
        echo -e "   • Docker Desktop with Kubernetes enabled"
        echo -e "   • Minikube: minikube start"
        echo -e "   • Kind: kind create cluster"
        echo -e "   • K3s or other local cluster"
        exit 1
    else
        local cluster_info=$(kubectl config current-context)
        echo -e "${GREEN}✅ Kubernetes cluster accessible: ${cluster_info}${NC}"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}❌ Missing required tools:${NC}"
        for tool in "${missing_tools[@]}"; do
            echo -e "${RED}   - ${tool}${NC}"
        done
        echo ""
        echo -e "${YELLOW}Please install missing tools and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🎉 All prerequisites satisfied!${NC}"
    echo ""
}

# Function to build Docker image
build_docker_image() {
    print_step "🐳 STEP 2: BUILDING DOCKER IMAGE"
    
    echo -e "${YELLOW}🔨 Building Chronicle Demo Docker image...${NC}"
    
    # Build the Maven application first
    if [ ! -f "target/chronicle-demo-1.0.0.jar" ]; then
        echo -e "${BLUE}📦 Building Maven application...${NC}"
        mvn clean package -DskipTests
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Maven build failed${NC}"
            exit 1
        fi
    fi
    
    # Build Docker image
    docker build -t chronicle-demo:latest .
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Docker build failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker image built successfully${NC}"
    echo ""
}

# Function to validate Helm chart
validate_helm_chart() {
    print_step "✅ STEP 3: VALIDATING HELM CHART"
    
    echo -e "${YELLOW}🔍 Linting Helm chart...${NC}"
    helm lint helm/chronicle-demo
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Helm chart validation failed${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🔍 Validating with local values...${NC}"
    helm lint helm/chronicle-demo -f ${VALUES_FILE}
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Helm chart validation with local values failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Helm chart validation passed${NC}"
    echo ""
}

# Function to deploy with Helm
deploy_with_helm() {
    print_step "🚀 STEP 4: DEPLOYING WITH HELM"
    
    echo -e "${YELLOW}📋 Deployment Configuration:${NC}"
    echo -e "   Chart: ${CHART_NAME}"
    echo -e "   Release: ${RELEASE_NAME}"
    echo -e "   Namespace: ${NAMESPACE}"
    echo -e "   Values: ${VALUES_FILE}"
    echo ""
    
    # Check if release already exists
    if helm list -n ${NAMESPACE} | grep -q ${RELEASE_NAME}; then
        echo -e "${YELLOW}⚠️  Release ${RELEASE_NAME} already exists. Upgrading...${NC}"
        helm upgrade ${RELEASE_NAME} helm/chronicle-demo \
            -f ${VALUES_FILE} \
            -n ${NAMESPACE} \
            --wait \
            --timeout=300s
    else
        echo -e "${BLUE}🚀 Installing new release...${NC}"
        helm install ${RELEASE_NAME} helm/chronicle-demo \
            -f ${VALUES_FILE} \
            -n ${NAMESPACE} \
            --wait \
            --timeout=300s
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Helm deployment successful${NC}"
    else
        echo -e "${RED}❌ Helm deployment failed${NC}"
        exit 1
    fi
    echo ""
}

# Function to verify deployment
verify_deployment() {
    print_step "🔍 STEP 5: VERIFYING DEPLOYMENT"
    
    echo -e "${YELLOW}📊 Checking deployment status...${NC}"
    
    # Check Helm release status
    helm status ${RELEASE_NAME} -n ${NAMESPACE}
    
    # Check pod status
    echo -e "${BLUE}🏃 Pod Status:${NC}"
    kubectl get pods -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE}
    
    # Check service status
    echo -e "${BLUE}🌐 Service Status:${NC}"
    kubectl get svc -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE}
    
    # Wait for pods to be ready
    echo -e "${YELLOW}⏳ Waiting for pods to be ready...${NC}"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} --timeout=300s
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ All pods are ready${NC}"
    else
        echo -e "${YELLOW}⚠️  Some pods may not be ready yet${NC}"
    fi
    echo ""
}

# Function to show access information
show_access_info() {
    print_step "🌐 STEP 6: ACCESS INFORMATION"
    
    # Get service information
    local service_type=$(kubectl get svc ${RELEASE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.type}')
    local service_port=$(kubectl get svc ${RELEASE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].port}')
    
    echo -e "${BLUE}📋 Service Information:${NC}"
    echo -e "   Type: ${service_type}"
    echo -e "   Port: ${service_port}"
    
    if [ "$service_type" = "NodePort" ]; then
        local node_port=$(kubectl get svc ${RELEASE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
        echo -e "   NodePort: ${node_port}"
        echo ""
        echo -e "${GREEN}🌐 Access URLs:${NC}"
        echo -e "   Local: http://localhost:${node_port}"
        echo -e "   Node: http://<node-ip>:${node_port}"
    elif [ "$service_type" = "LoadBalancer" ]; then
        local external_ip=$(kubectl get svc ${RELEASE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [ -n "$external_ip" ]; then
            echo -e "${GREEN}🌐 Access URL: http://${external_ip}:${service_port}${NC}"
        else
            echo -e "${YELLOW}⏳ LoadBalancer IP pending...${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo -e "   View pods: kubectl get pods -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE}"
    echo -e "   View logs: kubectl logs -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -f"
    echo -e "   Port forward: kubectl port-forward svc/${RELEASE_NAME} 8080:${service_port} -n ${NAMESPACE}"
    echo -e "   Uninstall: helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}"
    echo ""
}

# Function to test application
test_application() {
    print_step "🧪 STEP 7: TESTING APPLICATION"
    
    echo -e "${YELLOW}🔍 Testing application health...${NC}"
    
    # Port forward for testing
    echo -e "${BLUE}🔌 Setting up port forward...${NC}"
    kubectl port-forward svc/${RELEASE_NAME} 8080:8080 -n ${NAMESPACE} &
    local port_forward_pid=$!
    
    # Wait a moment for port forward to establish
    sleep 5
    
    # Test health endpoint
    if curl -f -s http://localhost:8080/ > /dev/null; then
        echo -e "${GREEN}✅ Application is responding to health checks${NC}"
    else
        echo -e "${YELLOW}⚠️  Application may still be starting up${NC}"
    fi
    
    # Clean up port forward
    kill $port_forward_pid 2>/dev/null || true
    
    echo ""
}

# Function to show final summary
show_summary() {
    print_step "🎉 DEPLOYMENT COMPLETE!"
    
    echo -e "${GREEN}🚀 Chronicle Demo has been successfully deployed locally!${NC}"
    echo ""
    echo -e "${BLUE}📊 Deployment Summary:${NC}"
    echo -e "   Release: ${RELEASE_NAME}"
    echo -e "   Namespace: ${NAMESPACE}"
    echo -e "   Chart Version: $(helm list -n ${NAMESPACE} | grep ${RELEASE_NAME} | awk '{print $9}')"
    echo -e "   Status: $(helm status ${RELEASE_NAME} -n ${NAMESPACE} -o json | jq -r '.info.status')"
    echo ""
    
    echo -e "${YELLOW}🔧 Management Commands:${NC}"
    echo -e "   Access app: kubectl port-forward svc/${RELEASE_NAME} 8080:8080 -n ${NAMESPACE}"
    echo -e "   View logs: kubectl logs -l app.kubernetes.io/instance=${RELEASE_NAME} -n ${NAMESPACE} -f"
    echo -e "   Scale up: kubectl scale deployment ${RELEASE_NAME} --replicas=2 -n ${NAMESPACE}"
    echo -e "   Upgrade: helm upgrade ${RELEASE_NAME} helm/chronicle-demo -f ${VALUES_FILE} -n ${NAMESPACE}"
    echo -e "   Uninstall: helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}"
    echo ""
    
    echo -e "${PURPLE}🎊 Happy testing with Chronicle Demo on Kubernetes! 🎊${NC}"
}

# Main execution flow
main() {
    # Make sure we're in the right directory
    if [ ! -f "pom.xml" ] || [ ! -d "helm/chronicle-demo" ]; then
        echo -e "${RED}❌ Please run this script from the chronicle-demo root directory${NC}"
        exit 1
    fi
    
    # Execute deployment steps
    check_prerequisites
    build_docker_image
    validate_helm_chart
    deploy_with_helm
    verify_deployment
    show_access_info
    test_application
    show_summary
}

# Handle script interruption
trap 'echo -e "\n${RED}❌ Deployment interrupted by user${NC}"; exit 1' INT

# Run main function
main "$@"