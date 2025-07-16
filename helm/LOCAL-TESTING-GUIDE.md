# Chronicle Demo - Local Helm Testing Guide

This guide helps you test the Chronicle Demo Helm chart in your local Kubernetes environment before deploying to OpenShift.

## 🎯 Prerequisites

### Required Tools
- **Helm 3.x**: `brew install helm`
- **kubectl**: `brew install kubectl`
- **Docker**: Docker Desktop with Kubernetes enabled
- **Maven**: `brew install maven`

### Local Kubernetes Options
Choose one of these local Kubernetes environments:

#### Option 1: Docker Desktop (Recommended)
1. Install Docker Desktop
2. Enable Kubernetes in Docker Desktop settings
3. Verify: `kubectl cluster-info`

#### Option 2: Minikube
```bash
# Install minikube
brew install minikube

# Start cluster
minikube start --memory=4096 --cpus=2

# Verify
kubectl cluster-info
```

#### Option 3: Kind
```bash
# Install kind
brew install kind

# Create cluster
kind create cluster --name chronicle-demo

# Verify
kubectl cluster-info
```

## 🚀 Quick Start

### One-Command Deployment
```bash
./helm/deploy-local.sh
```

This script will:
1. ✅ Check all prerequisites
2. 🐳 Build the Docker image
3. ✅ Validate the Helm chart
4. 🚀 Deploy to local Kubernetes
5. 🔍 Verify the deployment
6. 🌐 Show access information
7. 🧪 Test the application

## 📋 Manual Deployment Steps

### Step 1: Build Docker Image
```bash
# Build Maven application
mvn clean package -DskipTests

# Build Docker image
docker build -t chronicle-demo:latest .
```

### Step 2: Validate Helm Chart
```bash
# Lint the chart
helm lint helm/chronicle-demo

# Validate with local values
helm lint helm/chronicle-demo -f helm/chronicle-demo/values-local.yaml

# Dry run to see generated manifests
helm install chronicle-demo-test helm/chronicle-demo \
  -f helm/chronicle-demo/values-local.yaml \
  --dry-run --debug
```

### Step 3: Deploy to Kubernetes
```bash
# Install the chart
helm install chronicle-demo-local helm/chronicle-demo \
  -f helm/chronicle-demo/values-local.yaml \
  --wait --timeout=300s

# Or upgrade if already installed
helm upgrade chronicle-demo-local helm/chronicle-demo \
  -f helm/chronicle-demo/values-local.yaml \
  --wait --timeout=300s
```

### Step 4: Verify Deployment
```bash
# Check Helm release
helm status chronicle-demo-local

# Check pods
kubectl get pods -l app.kubernetes.io/instance=chronicle-demo-local

# Check services
kubectl get svc -l app.kubernetes.io/instance=chronicle-demo-local

# Check logs
kubectl logs -l app.kubernetes.io/instance=chronicle-demo-local -f
```

## 🌐 Accessing the Application

### Method 1: Port Forward (Recommended)
```bash
kubectl port-forward svc/chronicle-demo-local 8080:8080
# Access at: http://localhost:8080
```

### Method 2: NodePort (if configured)
```bash
# Get NodePort
kubectl get svc chronicle-demo-local -o jsonpath='{.spec.ports[0].nodePort}'
# Access at: http://localhost:<nodeport>
```

### Method 3: Ingress (if configured)
```bash
# Check ingress
kubectl get ingress
# Access via ingress host
```

## 🔧 Configuration Options

### Local Values Override
The `values-local.yaml` file contains optimized settings for local testing:

```yaml
# Key differences from production values:
image:
  repository: chronicle-demo  # Local image
  tag: latest
  pullPolicy: IfNotPresent

deployment:
  replicaCount: 1  # Single replica for testing

resources:
  limits:
    cpu: 1000m     # Reduced for local testing
    memory: 2Gi

persistence:
  enabled: false   # Use emptyDir for testing

autoscaling:
  enabled: false   # Disabled for simplicity

service:
  type: NodePort   # Easy local access
```

### Custom Configuration
Create your own values file:

```bash
# Copy and modify
cp helm/chronicle-demo/values-local.yaml my-values.yaml

# Deploy with custom values
helm install chronicle-demo-local helm/chronicle-demo -f my-values.yaml
```

## 🧪 Testing Scenarios

### Test 1: Basic Functionality
```bash
# Port forward
kubectl port-forward svc/chronicle-demo-local 8080:8080 &

# Test health endpoint
curl http://localhost:8080/

# Check if Chronicle is working
kubectl logs -l app.kubernetes.io/instance=chronicle-demo-local | grep "Chronicle"
```

### Test 2: Scaling
```bash
# Scale up
kubectl scale deployment chronicle-demo-local --replicas=2

# Verify scaling
kubectl get pods -l app.kubernetes.io/instance=chronicle-demo-local

# Scale down
kubectl scale deployment chronicle-demo-local --replicas=1
```

### Test 3: Configuration Changes
```bash
# Update values
helm upgrade chronicle-demo-local helm/chronicle-demo \
  -f helm/chronicle-demo/values-local.yaml \
  --set deployment.replicaCount=2

# Verify update
kubectl get pods -l app.kubernetes.io/instance=chronicle-demo-local
```

### Test 4: Persistence (Optional)
```bash
# Enable persistence
helm upgrade chronicle-demo-local helm/chronicle-demo \
  -f helm/chronicle-demo/values-local.yaml \
  --set persistence.enabled=true \
  --set persistence.size=1Gi

# Check PVC
kubectl get pvc
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Image Pull Errors
```bash
# Check if image exists locally
docker images | grep chronicle-demo

# Rebuild if needed
docker build -t chronicle-demo:latest .
```

#### 2. Pod Not Starting
```bash
# Check pod events
kubectl describe pod -l app.kubernetes.io/instance=chronicle-demo-local

# Check logs
kubectl logs -l app.kubernetes.io/instance=chronicle-demo-local
```

#### 3. Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints chronicle-demo-local

# Check if pods are ready
kubectl get pods -l app.kubernetes.io/instance=chronicle-demo-local
```

#### 4. Resource Constraints
```bash
# Check node resources
kubectl top nodes

# Reduce resource requests in values-local.yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
```

### Debug Commands
```bash
# Get all resources
kubectl get all -l app.kubernetes.io/instance=chronicle-demo-local

# Describe deployment
kubectl describe deployment chronicle-demo-local

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp

# Shell into pod
kubectl exec -it deployment/chronicle-demo-local -- /bin/bash
```

## 🧹 Cleanup

### Remove Helm Release
```bash
# Uninstall release
helm uninstall chronicle-demo-local

# Verify cleanup
kubectl get all -l app.kubernetes.io/instance=chronicle-demo-local
```

### Remove Docker Image
```bash
# Remove local image
docker rmi chronicle-demo:latest
```

### Clean Kubernetes Resources
```bash
# Remove any leftover resources
kubectl delete all -l app.kubernetes.io/instance=chronicle-demo-local
kubectl delete pvc -l app.kubernetes.io/instance=chronicle-demo-local
```

## 📊 Performance Testing

### Load Testing
```bash
# Port forward
kubectl port-forward svc/chronicle-demo-local 8080:8080 &

# Simple load test (if you have hey installed)
hey -n 1000 -c 10 http://localhost:8080/

# Or use curl in a loop
for i in {1..100}; do curl -s http://localhost:8080/ > /dev/null; done
```

### Resource Monitoring
```bash
# Watch resource usage
kubectl top pods -l app.kubernetes.io/instance=chronicle-demo-local

# Monitor in real-time
watch kubectl get pods -l app.kubernetes.io/instance=chronicle-demo-local
```

## 🎯 Next Steps

Once local testing is successful:

1. **OpenShift Deployment**: Use the main `values.yaml` with OpenShift-specific configurations
2. **CI/CD Integration**: Integrate Helm deployment into your CI/CD pipeline
3. **Production Tuning**: Adjust resource limits, persistence, and scaling for production
4. **Monitoring Setup**: Enable monitoring and alerting for production deployment

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Chronicle Map Documentation](https://github.com/OpenHFT/Chronicle-Map)
- [Chronicle Queue Documentation](https://github.com/OpenHFT/Chronicle-Queue)

---

**Happy testing! 🚀** Your local Kubernetes environment is perfect for validating the Helm chart before production deployment.