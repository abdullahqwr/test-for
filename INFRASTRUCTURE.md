# Error Team - BurgerBuilder Azure Infrastructure

Complete Azure Kubernetes Service (AKS) infrastructure for the BurgerBuilder application with monitoring, observability, and CI/CD.

## 📁 Project Structure

```
final-project-5/
├── .github/
│   └── workflows/
│       ├── pr-validation.yml          # PR validation
│       ├── terraform-plan.yml         # Terraform plan on PR
│       ├── build-test.yml             # Build and test on PR
│       └── deploy.yml                 # Deploy on merge
├── scripts/
│   ├── setup-azure.sh                 # Setup ACR and Storage
│   └── push-images.sh                 # Push images to ACR/DockerHub
├── terraform/
│   ├── main.tf                        # Root configuration
│   ├── variables.tf                   # Root variables
│   ├── outputs.tf                     # Root outputs
│   ├── terraform.tfvars.example       # Example values
│   └── modules/
│       ├── aks/                       # AKS cluster module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── networking/                # VNet and subnets
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── database/                  # Azure PostgreSQL
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── monitoring/                # Logs & AppInsights
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── app_gateway/               # Application Gateway
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── k8s/
│   ├── namespace.yaml                 # Kubernetes namespace
│   ├── deployments/
│   │   ├── frontend-deployment.yaml
│   │   ├── backend-deployment.yaml
│   │   └── database-deployment.yaml
│   ├── services/
│   │   ├── frontend-service.yaml
│   │   ├── backend-service.yaml
│   │   └── database-service.yaml
│   ├── ingress/
│   │   └── ingress.yaml
│   ├── configmaps/
│   │   ├── frontend-config.yaml
│   │   └── backend-config.yaml
│   └── secrets/
│       └── database-secret.yaml
├── backend/
│   └── Dockerfile
├── frontend/
│   └── Dockerfile
├── .env.local                         # Local credentials (gitignored)
├── .gitignore
└── README.md
```

## 🚀 Getting Started

### Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.0
- Docker installed
- kubectl installed
- Git

### Step 1: Setup Azure Infrastructure

```bash
# Set environment variables
export PREFIX="errorteam"
export LOCATION="eastus"

# Source credentials
source .env.local

# Run setup script
chmod +x scripts/setup-azure.sh
./scripts/setup-azure.sh
```

This creates:
- Resource Group: `errorteam-final-solution` (empty, for Terraform)
- Resource Group: `errorteam-final-infra` (ACR + Storage)
- Azure Container Registry: `errorteamacr`
- Storage Account: `errorteamtfstate` (for Terraform state)

### Step 2: Push Docker Images

```bash
# Push images to ACR and Docker Hub
chmod +x scripts/push-images.sh
./scripts/push-images.sh
```

Your existing Docker images will be tagged and pushed:
- `frontimg:latest` → `errorteamacr.azurecr.io/errorteam-frontend:latest`
- `backend-test:latest` → `errorteamacr.azurecr.io/errorteam-backend:latest`

### Step 3: Initialize Terraform

```bash
cd terraform

# Initialize Terraform with Azure backend
terraform init

# Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Step 4: Configure kubectl

```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group errorteam-final-solution \
  --name errorteam-aks-cluster

# Verify connection
kubectl get nodes
```

### Step 5: Deploy Applications

```bash
# Create namespace
kubectl apply -f k8s/namespace.yaml

# Deploy applications
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
kubectl apply -f k8s/ingress/
```

## 🔐 Secrets Management

Never commit sensitive data! Use these patterns:

```bash
# Create Kubernetes secrets
kubectl create secret generic db-credentials \
  --from-literal=username=errorteamadmin \
  --from-literal=password=<YOUR_PASSWORD> \
  -n errorteam

# Create ACR pull secret
kubectl create secret docker-registry acr-secret \
  --docker-server=errorteamacr.azurecr.io \
  --docker-username=<ACR_USERNAME> \
  --docker-password=<ACR_PASSWORD> \
  -n errorteam
```

## 📊 Monitoring & Observability

### Application Insights

Access metrics at: Azure Portal → Application Insights → `errorteam-appinsights`

### Log Analytics

```bash
# Query logs
az monitor log-analytics query \
  --workspace <WORKSPACE_ID> \
  --analytics-query "ContainerLog | limit 10"
```

### Kubernetes Dashboard

```bash
# Deploy dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
kubectl apply -f k8s/monitoring/dashboard-admin.yaml

# Get token
kubectl -n kubernetes-dashboard create token admin-user

# Port forward
kubectl proxy
```

Access at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

## 🔄 CI/CD Workflows

### PR Workflow

On Pull Request:
1. Validate code
2. Run tests
3. Terraform plan
4. Build Docker images
5. Comment plan on PR

### Deploy Workflow

On merge to main:
1. Run tests
2. Build Docker images
3. Push to ACR
4. Terraform apply
5. Deploy to AKS
6. Run smoke tests

## 🏗️ Infrastructure Components

### AKS Cluster
- **Nodes**: 2 (auto-scaling 1-5)
- **VM Size**: Standard_D2s_v3
- **Kubernetes**: v1.28
- **Network**: Azure CNI with Calico

### Database
- **Type**: Azure Database for PostgreSQL Flexible Server
- **SKU**: B_Standard_B1ms
- **Storage**: 32GB
- **Backup**: 7 days retention

### Networking
- **VNet**: 10.1.0.0/16
- **AKS Subnet**: 10.1.1.0/24
- **DB Subnet**: 10.1.2.0/24
- **AppGW Subnet**: 10.1.3.0/24

### Application Gateway
- **SKU**: Standard_v2
- **Tier**: Standard_v2
- **Capacity**: 2 instances

## 🧪 Testing

```bash
# Test frontend locally
docker run -p 3000:80 frontimg:latest

# Test backend locally
docker run -p 8080:8080 backend-test:latest

# Test in Kubernetes
kubectl port-forward svc/frontend-service 8080:80 -n errorteam
kubectl port-forward svc/backend-service 8081:8080 -n errorteam
```

## 📝 Environment Variables

Create `.env.local` (already created, not in git):

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export DOCKER_HUB_USERNAME="abdullahkhlead"
export DOCKER_HUB_TOKEN="your-token"
export PREFIX="errorteam"
export LOCATION="eastus"
```

## 🗑️ Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace errorteam

# Destroy Terraform infrastructure
cd terraform
terraform destroy

# Delete resource groups (if needed)
az group delete --name errorteam-final-solution --yes
az group delete --name errorteam-final-infra --yes
```

## 📚 Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 👥 Team

**Error Team**
- Project: BurgerBuilder
- Infrastructure: Azure AKS
- CI/CD: GitHub Actions

## 📄 License

This project is for educational purposes.
