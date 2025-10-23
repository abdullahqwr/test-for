# Error Team - Quick Setup Guide

## 🚀 Quick Start (5 Steps)

### Step 1: Set Environment Variables
```bash
# Copy and edit the environment file
cp .env.local.example .env.local
# Edit .env.local with your credentials (already provided)
source .env.local
```

### Step 2: Setup Azure Infrastructure
```bash
chmod +x scripts/setup-azure.sh
./scripts/setup-azure.sh
```

**This creates:**
- ✅ Resource groups (`errorteam-final-solution`, `errorteam-final-infra`)
- ✅ Azure Container Registry (`errorteamacr`)
- ✅ Storage Account for Terraform state (`errorteamtfstate`)

### Step 3: Push Docker Images
```bash
chmod +x scripts/push-images.sh
./scripts/push-images.sh
```

**This pushes:**
- ✅ `frontimg:latest` → ACR
- ✅ `backend-test:latest` → ACR
- ✅ Also pushes to Docker Hub (your-dockerhub-username)

### Step 4: Deploy Infrastructure with Terraform
```bash
cd terraform

# Initialize
terraform init

# Create terraform.tfvars
cat > terraform.tfvars << EOF
prefix = "errorteam"
solution_resource_group_name = "errorteam-final-solution"
acr_id = "/subscriptions/your-subscription-id/resourceGroups/errorteam-final-infra/providers/Microsoft.ContainerRegistry/registries/errorteamacr"
db_admin_password = "YourSecurePassword123!"
EOF

# Plan and Apply
terraform plan -out=tfplan
terraform apply tfplan
```

**This creates:**
- ✅ AKS Cluster
- ✅ Virtual Network
- ✅ Azure PostgreSQL Database
- ✅ Application Gateway
- ✅ Log Analytics & Application Insights

### Step 5: Deploy Applications to Kubernetes
```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group errorteam-final-solution \
  --name errorteam-aks-cluster

# Create ACR pull secret
ACR_USERNAME=$(az acr credential show --name errorteamacr --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name errorteamacr --query "passwords[0].value" -o tsv)

kubectl create secret docker-registry acr-secret \
  --docker-server=errorteamacr.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  -n errorteam

# Create database secret
kubectl create secret generic db-credentials \
  --from-literal=username=errorteamadmin \
  --from-literal=password=YourSecurePassword123! \
  -n errorteam

# Deploy applications
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
kubectl apply -f k8s/ingress/

# Check deployment
kubectl get pods -n errorteam
kubectl get svc -n errorteam
kubectl get ingress -n errorteam
```

## 🔐 GitHub Secrets Setup

Add these secrets to your GitHub repository:

1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Add these secrets:

```
ARM_SUBSCRIPTION_ID = your-subscription-id
ARM_TENANT_ID = your-tenant-id
ARM_CLIENT_ID = your-client-id
ARM_CLIENT_SECRET = your-client-secret-here
DOCKER_HUB_USERNAME = your-dockerhub-username
DOCKER_HUB_TOKEN = your-docker-hub-token-here
```

## 📊 Verify Deployment

```bash
# Check pods
kubectl get pods -n errorteam -w

# Check logs
kubectl logs -f deployment/frontend -n errorteam
kubectl logs -f deployment/backend -n errorteam

# Port forward for testing
kubectl port-forward svc/frontend-service 8080:80 -n errorteam
```

Visit: http://localhost:8080

## 🔧 Troubleshooting

### Images not pulling?
```bash
# Verify ACR secret
kubectl get secret acr-secret -n errorteam

# Recreate if needed
kubectl delete secret acr-secret -n errorteam
# Then create again
```

### Database connection issues?
```bash
# Check database secret
kubectl get secret db-credentials -n errorteam -o yaml

# Check backend logs
kubectl logs deployment/backend -n errorteam
```

### Terraform issues?
```bash
# Re-initialize
cd terraform
rm -rf .terraform
terraform init

# Check state
terraform show
```

## 🗑️ Cleanup

```bash
# Delete K8s resources
kubectl delete namespace errorteam

# Destroy Terraform
cd terraform
terraform destroy

# Delete resource groups (if needed)
az group delete --name errorteam-final-solution --yes --no-wait
az group delete --name errorteam-final-infra --yes --no-wait
```

## 📝 Notes

- All resources are prefixed with `errorteam`
- Default location: `eastus`
- Team name: **Error Team**
- Project: BurgerBuilder

## 📚 Documentation

- Full docs: See `INFRASTRUCTURE.md`
- Terraform modules: See `terraform/modules/`
- K8s manifests: See `k8s/`

## ✅ Success Criteria

- [ ] Azure resources created
- [ ] Images pushed to ACR
- [ ] Terraform infrastructure deployed
- [ ] Applications running in AKS
- [ ] Ingress accessible
- [ ] Monitoring enabled
- [ ] CI/CD workflows configured

---

**Error Team** | BurgerBuilder Project | Azure AKS Infrastructure
