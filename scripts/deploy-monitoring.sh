#!/bin/bash

set -euo pipefail

# Error Team - Monitoring Stack Deployment Script
# Deploys Prometheus and Grafana to AKS cluster

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Not connected to a Kubernetes cluster. Run: az aks get-credentials --resource-group errorteam-final-solution --name errorteam-aks-cluster"
    exit 1
fi

CURRENT_CONTEXT=$(kubectl config current-context)
print_status "Current Kubernetes context: ${CURRENT_CONTEXT}"
echo ""
read -p "Deploy monitoring to this cluster? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

echo ""
print_status "================================================"
print_status "Deploying Monitoring Stack (Prometheus + Grafana)"
print_status "================================================"
echo ""

# Create monitoring namespace
print_status "Creating monitoring namespace..."
kubectl apply -f ../k8s/monitoring/namespace.yaml
print_success "Monitoring namespace created"
echo ""

# Deploy Prometheus RBAC
print_status "Configuring Prometheus RBAC..."
kubectl apply -f ../k8s/monitoring/prometheus-rbac.yaml
print_success "Prometheus RBAC configured"
echo ""

# Deploy Prometheus ConfigMap
print_status "Deploying Prometheus configuration..."
kubectl apply -f ../k8s/monitoring/prometheus-config.yaml
print_success "Prometheus configuration deployed"
echo ""

# Deploy Prometheus
print_status "Deploying Prometheus..."
kubectl apply -f ../k8s/monitoring/prometheus-deployment.yaml
print_success "Prometheus deployed"
echo ""

# Deploy Grafana ConfigMaps
print_status "Deploying Grafana configuration..."
kubectl apply -f ../k8s/monitoring/grafana-config.yaml
print_success "Grafana configuration deployed"
echo ""

# Deploy Grafana
print_status "Deploying Grafana..."
kubectl apply -f ../k8s/monitoring/grafana-deployment.yaml
print_success "Grafana deployed"
echo ""

# Deploy Grafana Ingress
print_status "Deploying Grafana ingress..."
kubectl apply -f ../k8s/monitoring/grafana-ingress.yaml
print_success "Grafana ingress deployed"
echo ""

# Wait for pods to be ready
print_status "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=120s || print_warning "Prometheus might take longer to start"

print_status "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=120s || print_warning "Grafana might take longer to start"

echo ""
print_success "================================================"
print_success "Monitoring Stack Deployed Successfully!"
print_success "================================================"
echo ""

# Get service information
PROMETHEUS_SVC=$(kubectl get svc prometheus -n monitoring -o jsonpath='{.spec.clusterIP}')
GRAFANA_SVC=$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.clusterIP}')

echo "📊 Monitoring Services:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Prometheus:"
echo "  Cluster IP: ${PROMETHEUS_SVC}:9090"
echo "  Port Forward: kubectl port-forward -n monitoring svc/prometheus 9090:9090"
echo "  Access: http://localhost:9090"
echo ""
echo "Grafana:"
echo "  Cluster IP: ${GRAFANA_SVC}:3000"
echo "  Port Forward: kubectl port-forward -n monitoring svc/grafana 3000:3000"
echo "  Access: http://localhost:3000"
echo "  Username: admin"
echo "  Password: errorteam2025"
echo ""
echo "Via Ingress (if configured):"
echo "  Grafana: http://grafana.errorteam.com (configure DNS first)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_status "Available Commands:"
echo "  • View Prometheus pods:   kubectl get pods -n monitoring -l app=prometheus"
echo "  • View Grafana pods:      kubectl get pods -n monitoring -l app=grafana"
echo "  • View all monitoring:    kubectl get all -n monitoring"
echo "  • Prometheus logs:        kubectl logs -n monitoring -l app=prometheus -f"
echo "  • Grafana logs:           kubectl logs -n monitoring -l app=grafana -f"
echo ""

print_warning "Security Note:"
print_warning "  The default Grafana password is 'errorteam2025'"
print_warning "  Please change it after first login!"
echo ""

# Check pod status
print_status "Current Pod Status:"
kubectl get pods -n monitoring

echo ""
print_success "Deployment complete! 🎉"
