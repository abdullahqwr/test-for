# ✅ Deployment Checklist - Error Team

## 📋 Pre-Deployment Checklist

### Environment Setup
- [ ] Azure CLI installed (`az --version`)
- [ ] Azure CLI logged in (`az login`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] Terraform installed (`terraform version`)
- [ ] Docker Desktop running (`docker ps`)
- [ ] Git configured
- [ ] VS Code with Azure extensions (optional)

### Credentials & Configuration
- [ ] `.env.local` file created with all credentials
- [ ] Azure Service Principal credentials set
  - [ ] `ARM_SUBSCRIPTION_ID`
  - [ ] `ARM_TENANT_ID`
  - [ ] `ARM_CLIENT_ID`
  - [ ] `ARM_CLIENT_SECRET`
- [ ] Docker Hub credentials set
  - [ ] `DOCKER_HUB_USERNAME`
  - [ ] `DOCKER_HUB_TOKEN`
- [ ] Project configuration set
  - [ ] `PREFIX=errorteam`
  - [ ] `LOCATION=eastus`

### Docker Images Ready
- [ ] Frontend image built (`frontimg:latest`)
- [ ] Backend image built (`backend-test:latest`)
- [ ] Images verified (`docker images`)

---

## 🚀 Deployment Checklist

### Phase 1: Azure Infrastructure Setup

- [ ] Source environment variables
  ```bash
  source .env.local
  ```

- [ ] Make setup script executable
  ```bash
  chmod +x scripts/setup-azure.sh
  ```

- [ ] Run Azure setup script
  ```bash
  ./scripts/setup-azure.sh
  ```

- [ ] Verify resource groups created
  ```bash
  az group list --output table | grep errorteam
  ```
  - [ ] `errorteam-tfstate` exists
  - [ ] `errorteam-final-infra` exists
  - [ ] `errorteam-final-solution` exists

- [ ] Verify ACR created
  ```bash
  az acr show --name errorteamacr --resource-group errorteam-final-infra
  ```

- [ ] Verify Storage Account created
  ```bash
  az storage account show --name errorteamtfstate --resource-group errorteam-tfstate
  ```

- [ ] Credentials saved in `.azure-credentials` file

---

### Phase 2: Terraform Backend Initialization

- [ ] Navigate to terraform directory
  ```bash
  cd terraform
  ```

- [ ] Make init script executable
  ```bash
  chmod +x ../scripts/init-terraform-backend.sh
  ```

- [ ] Run Terraform backend initialization
  ```bash
  ../scripts/init-terraform-backend.sh
  ```

- [ ] Verify Terraform initialized
  - [ ] `.terraform/` directory created
  - [ ] Backend configured with Azure Storage

---

### Phase 3: Push Docker Images

- [ ] Navigate back to project root
  ```bash
  cd ..
  ```

- [ ] Make push script executable
  ```bash
  chmod +x scripts/push-images.sh
  ```

- [ ] Run image push script
  ```bash
  ./scripts/push-images.sh
  ```

- [ ] Verify images in ACR
  ```bash
  az acr repository list --name errorteamacr --output table
  ```
  - [ ] `errorteam-frontend` exists
  - [ ] `errorteam-backend` exists

- [ ] Verify images in Docker Hub (optional)
  ```bash
  # Check on hub.docker.com or via CLI
  ```

---

### Phase 4: Deploy Infrastructure with Terraform

- [ ] Navigate to terraform directory
  ```bash
  cd terraform
  ```

- [ ] Copy terraform.tfvars.example
  ```bash
  cp terraform.tfvars.example terraform.tfvars
  ```

- [ ] Edit `terraform.tfvars` with your values
  - [ ] Set `acr_id` (get from ACR)
    ```bash
    az acr show --name errorteamacr --resource-group errorteam-final-infra --query "id" -o tsv
    ```
  - [ ] Set `db_admin_password` (strong password)
  - [ ] Review other variables

- [ ] Run Terraform plan
  ```bash
  terraform plan -out=tfplan
  ```

- [ ] Review plan output
  - [ ] Application Gateway will be created
  - [ ] AKS cluster will be created (with AGIC)
  - [ ] VNet and subnets will be created
  - [ ] PostgreSQL will be created
  - [ ] Monitoring resources will be created

- [ ] Apply Terraform plan
  ```bash
  terraform apply tfplan
  ```
  ⏱️ This will take **10-15 minutes**

- [ ] Verify deployment
  ```bash
  terraform output
  ```
  - [ ] AKS cluster name displayed
  - [ ] App Gateway public IP displayed
  - [ ] Database endpoint displayed

---

### Phase 5: Connect to AKS Cluster

- [ ] Get AKS credentials
  ```bash
  az aks get-credentials --resource-group errorteam-final-solution --name errorteam-aks-cluster --overwrite-existing
  ```

- [ ] Verify connection
  ```bash
  kubectl cluster-info
  ```

- [ ] Check nodes
  ```bash
  kubectl get nodes
  ```
  - [ ] All nodes in `Ready` state

- [ ] Check AGIC pods
  ```bash
  kubectl get pods -n kube-system -l app=ingress-appgw
  ```
  - [ ] AGIC pod(s) running

---

### Phase 6: Deploy Applications

- [ ] Navigate back to project root
  ```bash
  cd ..
  ```

- [ ] Create namespace
  ```bash
  kubectl apply -f k8s/namespace.yaml
  ```

- [ ] Create ACR pull secret
  ```bash
  # Get ACR credentials from .azure-credentials file
  ACR_USERNAME=$(grep ACR_USERNAME .azure-credentials | cut -d'=' -f2 | tr -d '"')
  ACR_PASSWORD=$(grep ACR_PASSWORD .azure-credentials | cut -d'=' -f2 | tr -d '"')
  
  kubectl create secret docker-registry acr-secret \
    --docker-server=errorteamacr.azurecr.io \
    --docker-username=$ACR_USERNAME \
    --docker-password=$ACR_PASSWORD \
    --namespace=errorteam
  ```

- [ ] Create database credentials secret
  ```bash
  kubectl create secret generic db-credentials \
    --from-literal=username=your-db-admin-username \
    --from-literal=password=your-db-admin-password \
    --namespace=errorteam
  ```

- [ ] Deploy ConfigMaps
  ```bash
  kubectl apply -f k8s/configmaps/
  ```

- [ ] Deploy applications
  ```bash
  kubectl apply -f k8s/deployments/
  kubectl apply -f k8s/services/
  kubectl apply -f k8s/ingress/
  ```

- [ ] Wait for pods to be ready
  ```bash
  kubectl wait --for=condition=ready pod --all -n errorteam --timeout=300s
  ```

- [ ] Check pod status
  ```bash
  kubectl get pods -n errorteam
  ```
  - [ ] frontend pods: `Running` (2/2)
  - [ ] backend pods: `Running` (2/2)

- [ ] Check ingress
  ```bash
  kubectl get ingress -n errorteam
  ```
  - [ ] Ingress has ADDRESS (App Gateway IP)

---

### Phase 7: Deploy Monitoring Stack

- [ ] Make monitoring script executable
  ```bash
  chmod +x scripts/deploy-monitoring.sh
  ```

- [ ] Run monitoring deployment
  ```bash
  ./scripts/deploy-monitoring.sh
  ```

- [ ] Verify monitoring pods
  ```bash
  kubectl get pods -n monitoring
  ```
  - [ ] Prometheus pod: `Running`
  - [ ] Grafana pod: `Running`

- [ ] Port-forward to Grafana
  ```bash
  kubectl port-forward -n monitoring svc/grafana 3000:3000
  ```

- [ ] Access Grafana
  - [ ] Open http://localhost:3000
  - [ ] Login with `admin` / `errorteam2025`
  - [ ] Verify dashboards exist
  - [ ] Change default password!

- [ ] Port-forward to Prometheus (optional)
  ```bash
  kubectl port-forward -n monitoring svc/prometheus 9090:9090
  ```

- [ ] Access Prometheus
  - [ ] Open http://localhost:9090
  - [ ] Check targets (Status → Targets)
  - [ ] Verify targets are UP

---

## 🧪 Verification & Testing

### Application Testing

- [ ] Get Application Gateway Public IP
  ```bash
  az network public-ip show \
    --resource-group errorteam-final-solution \
    --name errorteam-appgw-pip \
    --query "ipAddress" -o tsv
  ```

- [ ] Test frontend access
  ```bash
  curl http://<APP_GATEWAY_IP>/
  ```
  - [ ] Returns HTML content

- [ ] Test backend API
  ```bash
  curl http://<APP_GATEWAY_IP>/api/health
  ```
  - [ ] Returns health status

- [ ] Test in browser
  - [ ] Open http://<APP_GATEWAY_IP>
  - [ ] Frontend loads correctly
  - [ ] API calls work
  - [ ] Can create burger orders

### AGIC Verification

- [ ] Check AGIC logs
  ```bash
  kubectl logs -n kube-system -l app=ingress-appgw --tail=50
  ```
  - [ ] No errors
  - [ ] Shows ingress synchronization

- [ ] Check Application Gateway backends
  ```bash
  az network application-gateway show-backend-health \
    --name errorteam-appgw \
    --resource-group errorteam-final-solution
  ```
  - [ ] Backend pools are healthy

### Monitoring Verification

- [ ] Check Prometheus targets
  - [ ] All targets UP in Prometheus UI

- [ ] Check Grafana dashboards
  - [ ] Kubernetes Cluster dashboard shows data
  - [ ] BurgerBuilder Application dashboard shows data

### Database Verification

- [ ] Check database connectivity from backend
  ```bash
  kubectl logs -n errorteam -l app=backend | grep -i database
  ```
  - [ ] No connection errors

- [ ] Test database query (if endpoint exists)
  ```bash
  curl http://<APP_GATEWAY_IP>/api/ingredients
  ```
  - [ ] Returns data from database

---

## 📊 Post-Deployment Tasks

### Security

- [ ] Change Grafana admin password
- [ ] Review NSG rules
- [ ] Configure SSL/TLS for ingress (if domain available)
- [ ] Enable WAF on Application Gateway (if needed)
- [ ] Review RBAC permissions

### DNS Configuration (Optional)

- [ ] Register domain name
- [ ] Create DNS A record pointing to App Gateway IP
- [ ] Update ingress with actual hostname
- [ ] Configure SSL certificate (cert-manager or App Gateway)

### Monitoring & Alerting

- [ ] Review Grafana dashboards
- [ ] Customize dashboards for your needs
- [ ] Set up alerting rules in Prometheus
- [ ] Configure notification channels (email, Slack)
- [ ] Test alert notifications

### Documentation

- [ ] Document custom configurations
- [ ] Share access credentials with team (securely)
- [ ] Document runbooks for common issues
- [ ] Create architecture diagrams (if needed)

### Backup & Disaster Recovery

- [ ] Verify database backups are enabled
- [ ] Test database restore procedure
- [ ] Document recovery procedures
- [ ] Set up GitOps for K8s manifests

### CI/CD Setup

- [ ] Add GitHub secrets
  - [ ] `ARM_SUBSCRIPTION_ID`
  - [ ] `ARM_TENANT_ID`
  - [ ] `ARM_CLIENT_ID`
  - [ ] `ARM_CLIENT_SECRET`
  - [ ] `DOCKER_HUB_USERNAME`
  - [ ] `DOCKER_HUB_TOKEN`
- [ ] Test PR validation workflow
- [ ] Test deployment workflow
- [ ] Set up branch protection rules

---

## 🔧 Troubleshooting Checklist

### If Terraform fails

- [ ] Check Azure credentials are valid
- [ ] Verify subscription has sufficient quota
- [ ] Check resource names don't already exist
- [ ] Review Terraform error messages
- [ ] Try `terraform refresh` and re-plan

### If pods won't start

- [ ] Check ACR pull secret exists
- [ ] Verify images exist in ACR
- [ ] Check pod logs: `kubectl logs <pod-name> -n errorteam`
- [ ] Describe pod: `kubectl describe pod <pod-name> -n errorteam`
- [ ] Check resource limits

### If AGIC isn't working

- [ ] Check AGIC pods are running
- [ ] Review AGIC logs for errors
- [ ] Verify ingress annotations are correct
- [ ] Check App Gateway backend health
- [ ] Ensure App Gateway has correct subnet

### If monitoring isn't collecting data

- [ ] Check Prometheus targets
- [ ] Verify pod annotations for scraping
- [ ] Check network policies aren't blocking
- [ ] Review Prometheus config
- [ ] Check Grafana datasource configuration

---

## 📝 Sign-Off

### Deployment Completed By
- **Name:** ________________
- **Date:** ________________
- **Time:** ________________

### Final Status
- [ ] All infrastructure deployed
- [ ] All applications running
- [ ] Monitoring operational
- [ ] Access verified
- [ ] Documentation updated
- [ ] Team notified

### Notes
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

**Error Team** | Deployment Checklist | Azure AKS Infrastructure
Use this checklist for every deployment! ✅
