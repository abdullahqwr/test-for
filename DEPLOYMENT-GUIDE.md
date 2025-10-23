# 🚀 Error Team - Quick Deployment Guide

## 📋 Prerequisites Checklist
- [ ] Azure CLI installed and logged in
- [ ] Docker installed with existing images (frontimg:latest, backend-test:latest)
- [ ] kubectl installed
- [ ] Git repository set up
- [ ] Environment variables in .env.local configured

---

## ⚡ 5-Step Deployment (New & Improved!)

### Step 1️⃣: Setup Azure Infrastructure (5 min)
```bash
source .env.local
chmod +x scripts/setup-azure.sh
./scripts/setup-azure.sh
```
**Creates:**
- ✅ errorteam-tfstate (isolated RG for Terraform state)
- ✅ errorteam-final-infra (ACR)
- ✅ errorteam-final-solution (empty, for Terraform)

---

### Step 2️⃣: Initialize Terraform Backend (2 min)
```bash
cd terraform
chmod +x ../scripts/init-terraform-backend.sh
../scripts/init-terraform-backend.sh
```
**Result:**
- ✅ Terraform with remote state in Azure Storage
- ✅ State locking enabled

---

### Step 3️⃣: Push Docker Images (3 min)
```bash
cd ..
chmod +x scripts/push-images.sh
./scripts/push-images.sh
```
**Pushes:**
- ✅ frontimg:latest → ACR & Docker Hub
- ✅ backend-test:latest → ACR & Docker Hub

---

### Step 4️⃣: Deploy Infrastructure (10 min)
```bash
cd terraform

# Edit terraform.tfvars with your values
cp terraform.tfvars.example terraform.tfvars
# Update: acr_id, db_admin_password

# Deploy
terraform plan -out=tfplan
terraform apply tfplan
```
**Deploys:**
- ✅ Application Gateway (with AGIC)
- ✅ AKS cluster (AGIC-enabled)
- ✅ VNet with subnets
- ✅ PostgreSQL database
- ✅ Log Analytics

---

### Step 5️⃣: Deploy Applications & Monitoring (5 min)
```bash
# Get AKS credentials
az aks get-credentials --resource-group errorteam-final-solution --name errorteam-aks-cluster

# Deploy applications
cd ..
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmaps/
kubectl create secret generic db-credentials \
  --from-literal=username=your-db-user \
  --from-literal=password=your-db-password \
  --namespace=errorteam
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
kubectl apply -f k8s/ingress/

# Deploy monitoring (Prometheus + Grafana)
chmod +x scripts/deploy-monitoring.sh
./scripts/deploy-monitoring.sh
```
**Deploys:**
- ✅ Frontend & Backend apps
- ✅ Prometheus (metrics)
- ✅ Grafana (dashboards)

---

## 🎯 Access Your Services

### Application (via AGIC)
```bash
# Get Application Gateway Public IP
az network public-ip show \
  --resource-group errorteam-final-solution \
  --name errorteam-appgw-pip \
  --query "ipAddress" -o tsv

# Access: http://<PUBLIC_IP>
```

### Grafana Dashboards
```bash
# Option 1: Port Forward (Immediate Access)
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Access: http://localhost:3000
# Username: admin
# Password: errorteam2025
```

### Prometheus
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access: http://localhost:9090
```

---

## 🔍 Verification Commands

### Check Everything is Running
```bash
# Applications
kubectl get pods -n errorteam
kubectl get svc -n errorteam
kubectl get ingress -n errorteam

# Monitoring
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# All resources
kubectl get all --all-namespaces
```

### View Logs
```bash
# Frontend
kubectl logs -n errorteam -l app=frontend -f

# Backend
kubectl logs -n errorteam -l app=backend -f

# Prometheus
kubectl logs -n monitoring -l app=prometheus -f

# Grafana
kubectl logs -n monitoring -l app=grafana -f
```

### Check AGIC Status
```bash
# AGIC pods (managed by AKS)
kubectl get pods -n kube-system -l app=ingress-appgw

# AGIC logs
kubectl logs -n kube-system -l app=ingress-appgw -f
```

---

## 🎨 Grafana Dashboards

**Pre-installed Dashboards:**

1. **Kubernetes Cluster**
   - Pod CPU usage
   - Pod memory usage
   - Node metrics

2. **BurgerBuilder Application**
   - HTTP request rate
   - Response time (p95)
   - Pod status
   - Error rates

**Access:** http://localhost:3000 (after port-forward)

---

## 🛠️ Troubleshooting

### Issue: Terraform init fails
```bash
# Re-run setup script
./scripts/setup-azure.sh

# Check storage account exists
az storage account show --name errorteamtfstate --resource-group errorteam-tfstate
```

### Issue: Pods not starting
```bash
# Check pod details
kubectl describe pod <POD_NAME> -n errorteam

# Check ACR secret
kubectl get secret acr-secret -n errorteam

# Recreate ACR secret if needed
kubectl create secret docker-registry acr-secret \
  --docker-server=errorteamacr.azurecr.io \
  --docker-username=<ACR_USERNAME> \
  --docker-password=<ACR_PASSWORD> \
  --namespace=errorteam
```

### Issue: Application Gateway not routing traffic
```bash
# Check AGIC pods
kubectl get pods -n kube-system -l app=ingress-appgw

# Check ingress status
kubectl describe ingress burgerbuilder-ingress -n errorteam

# Check AGIC logs
kubectl logs -n kube-system -l app=ingress-appgw -f
```

### Issue: Prometheus not scraping metrics
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Check Prometheus config
kubectl get configmap prometheus-config -n monitoring -o yaml
```

### Issue: Grafana shows "No data"
```bash
# Check Grafana logs
kubectl logs -n monitoring -l app=grafana -f

# Check Prometheus connection in Grafana
# Settings > Data Sources > Prometheus
# URL should be: http://prometheus:9090
```

---

## 🧹 Cleanup (When Done Testing)

```bash
# Delete Kubernetes resources
kubectl delete namespace errorteam
kubectl delete namespace monitoring

# Destroy infrastructure
cd terraform
terraform destroy

# Delete resource groups (if needed)
az group delete --name errorteam-final-solution --yes --no-wait
az group delete --name errorteam-final-infra --yes --no-wait
az group delete --name errorteam-tfstate --yes --no-wait
```

---

## 📊 Resource Groups Summary

| Resource Group | Contains | Purpose |
|----------------|----------|---------|
| **errorteam-tfstate** | Storage Account | Terraform state (ISOLATED) |
| **errorteam-final-infra** | ACR | Container images |
| **errorteam-final-solution** | AKS, App Gateway, VNet, PostgreSQL, Monitoring | Application infrastructure |

---

## 🔑 Important Credentials

**Grafana:**
- Username: `admin`
- Password: `errorteam2025` (CHANGE IN PRODUCTION!)

**Azure Container Registry:**
- Saved in: `.azure-credentials`

**Database:**
- Set in: `terraform.tfvars`
- Stored as: Kubernetes secret `db-credentials`

---

## 📞 Quick Reference

**Scripts:**
- `setup-azure.sh` - Create Azure infrastructure
- `init-terraform-backend.sh` - Initialize Terraform
- `push-images.sh` - Push Docker images
- `deploy-monitoring.sh` - Deploy Prometheus + Grafana

**Documentation:**
- `ENHANCEMENTS-SUMMARY.md` - New features explanation
- `SETUP-SUMMARY.md` - Complete setup guide
- `INFRASTRUCTURE.md` - Full infrastructure docs
- `QUICK-START.md` - Original quick start

---

## ✅ Success Indicators

You're successful when:
- [ ] All pods in `errorteam` namespace are Running
- [ ] All pods in `monitoring` namespace are Running
- [ ] Application Gateway has healthy backends
- [ ] Grafana shows live metrics
- [ ] Application accessible via App Gateway public IP
- [ ] AGIC pods running in kube-system

---

## 🎊 Architecture Highlights

**3 Key Enhancements:**
1. **Isolated Terraform State** - Separate RG for state safety
2. **AGIC** - App Gateway programmed from AKS automatically
3. **Prometheus + Grafana** - Complete monitoring inside cluster

**No Ansible** - Pure Terraform + Kubernetes + Bash!

---

**Error Team** | BurgerBuilder Project | Azure AKS
Ready to deploy! 🚀
