# 🏗️ Error Team - Complete Architecture Documentation

## 📐 Architecture Diagram

```
                                 INTERNET
                                    │
                                    ▼
        ┌───────────────────────────────────────────────────┐
        │     Azure Application Gateway (Public IP)         │
        │                                                   │
        │  • WAF Protection (optional)                      │
        │  • SSL/TLS Termination                            │
        │  • Path-based Routing                             │
        │  • Health Probes                                  │
        │                                                   │
        │  Managed by AGIC (runs inside AKS) ◄──────┐      │
        └───────────────┬───────────────────────────┘      │
                        │                                   │
                        ▼                                   │
        ┌───────────────────────────────────────────────────┼──────┐
        │               Azure Kubernetes Service (AKS)      │      │
        │                                                   │      │
        │  ┌────────────────────────────────────────────────┼────┐ │
        │  │        Namespace: kube-system                  │    │ │
        │  │  ┌──────────────────────────────────┐         │    │ │
        │  │  │  AGIC Pod (Ingress Controller)   │─────────┘    │ │
        │  │  │  • Watches Ingress resources     │              │ │
        │  │  │  • Programs App Gateway          │              │ │
        │  │  └──────────────────────────────────┘              │ │
        │  └─────────────────────────────────────────────────────┘ │
        │                                                           │
        │  ┌─────────────────────────────────────────────────────┐ │
        │  │        Namespace: errorteam (Applications)          │ │
        │  │                                                     │ │
        │  │   ┌──────────────────┐   ┌──────────────────┐     │ │
        │  │   │   Frontend Pod   │   │   Frontend Pod   │     │ │
        │  │   │   (React/Vite)   │   │   (React/Vite)   │     │ │
        │  │   └────────┬─────────┘   └─────────┬────────┘     │ │
        │  │            │                       │               │ │
        │  │            └───────────┬───────────┘               │ │
        │  │                        ▼                           │ │
        │  │              ┌──────────────────┐                  │ │
        │  │              │ Frontend Service │                  │ │
        │  │              │   (ClusterIP)    │                  │ │
        │  │              └──────────────────┘                  │ │
        │  │                                                     │ │
        │  │   ┌──────────────────┐   ┌──────────────────┐     │ │
        │  │   │   Backend Pod    │   │   Backend Pod    │     │ │
        │  │   │  (Spring Boot)   │   │  (Spring Boot)   │     │ │
        │  │   └────────┬─────────┘   └─────────┬────────┘     │ │
        │  │            │                       │               │ │
        │  │            └───────────┬───────────┘               │ │
        │  │                        ▼                           │ │
        │  │              ┌──────────────────┐                  │ │
        │  │              │ Backend Service  │                  │ │
        │  │              │   (ClusterIP)    │                  │ │
        │  │              └──────────────────┘                  │ │
        │  │                        │                           │ │
        │  │              ┌─────────┴──────────┐                │ │
        │  │              │                    │                │ │
        │  │              ▼                    ▼                │ │
        │  │   ┌──────────────────┐  ┌──────────────────┐      │ │
        │  │   │   ConfigMaps     │  │    Secrets       │      │ │
        │  │   │  (App Config)    │  │  (DB Creds)      │      │ │
        │  │   └──────────────────┘  └──────────────────┘      │ │
        │  └─────────────────────────────────────────────────────┘ │
        │                                                           │
        │  ┌─────────────────────────────────────────────────────┐ │
        │  │        Namespace: monitoring (Observability)        │ │
        │  │                                                     │ │
        │  │   ┌──────────────────┐                             │ │
        │  │   │  Prometheus Pod  │                             │ │
        │  │   │  • Scrapes pods  │                             │ │
        │  │   │  • Stores metrics│◄────────┐                   │ │
        │  │   │  • 15d retention │         │                   │ │
        │  │   └────────┬─────────┘         │                   │ │
        │  │            │                   │                   │ │
        │  │            │ ┌─────────────────┴─────────────┐     │ │
        │  │            │ │ Scrapes Metrics From:         │     │ │
        │  │            │ │ • Frontend pods               │     │ │
        │  │            │ │ • Backend pods (actuator)     │     │ │
        │  │            │ │ • Kubernetes API              │     │ │
        │  │            │ │ • Kubernetes nodes            │     │ │
        │  │            │ └───────────────────────────────┘     │ │
        │  │            ▼                                        │ │
        │  │   ┌──────────────────┐                             │ │
        │  │   │   Grafana Pod    │                             │ │
        │  │   │  • Dashboards    │                             │ │
        │  │   │  • Visualization │                             │ │
        │  │   │  • Alerting      │                             │ │
        │  │   └────────┬─────────┘                             │ │
        │  │            │                                        │ │
        │  │            ▼                                        │ │
        │  │   ┌──────────────────┐                             │ │
        │  │   │  Grafana Service │                             │ │
        │  │   │   (ClusterIP)    │                             │ │
        │  │   └──────────────────┘                             │ │
        │  │            │                                        │ │
        │  │            ▼                                        │ │
        │  │   ┌──────────────────┐                             │ │
        │  │   │ Grafana Ingress  │ ◄────── AGIC manages        │ │
        │  │   │  (via AGIC)      │                             │ │
        │  │   └──────────────────┘                             │ │
        │  └─────────────────────────────────────────────────────┘ │
        └───────────────────────────┬───────────────────────────────┘
                                    │
                                    ▼
        ┌───────────────────────────────────────────────────┐
        │   Azure Database for PostgreSQL Flexible Server   │
        │   • Private Endpoint                              │
        │   • Delegated Subnet                              │
        │   • Automatic Backups                             │
        └───────────────────────────────────────────────────┘

                                    │
                                    ▼
        ┌───────────────────────────────────────────────────┐
        │        Azure Monitor & Log Analytics              │
        │   • Application Insights                          │
        │   • Container Insights                            │
        │   • Performance Monitoring                        │
        └───────────────────────────────────────────────────┘
```

---

## 🗂️ Resource Groups Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                 Azure Subscription                              │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  errorteam-tfstate (ISOLATED)                             │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Storage Account: errorteamtfstate                  │  │ │
│  │  │  • Container: errorteam-tfstate                     │  │ │
│  │  │  • Blob: terraform.tfstate                          │  │ │
│  │  │  • State Locking Enabled                            │  │ │
│  │  │  • Encryption: AES-256                              │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  errorteam-final-infra                                    │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Azure Container Registry: errorteamacr             │  │ │
│  │  │  • errorteam-frontend:latest                        │  │ │
│  │  │  • errorteam-backend:latest                         │  │ │
│  │  │  • Admin enabled                                    │  │ │
│  │  │  • Basic SKU                                        │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  errorteam-final-solution (Main Infrastructure)           │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Virtual Network: errorteam-vnet                    │  │ │
│  │  │  • CIDR: 10.1.0.0/16                                │  │ │
│  │  │  • Subnet: aks-subnet (10.1.0.0/20)                 │  │ │
│  │  │  • Subnet: db-subnet (10.1.16.0/24)                 │  │ │
│  │  │  • Subnet: appgw-subnet (10.1.17.0/24)              │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Application Gateway: errorteam-appgw               │  │ │
│  │  │  • SKU: Standard_v2                                 │  │ │
│  │  │  • Public IP: errorteam-appgw-pip                   │  │ │
│  │  │  • Managed by AGIC                                  │  │ │
│  │  │  • Health Probes: Automatic                         │  │ │
│  │  │  • Backend Pools: Dynamic (AGIC)                    │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  AKS Cluster: errorteam-aks-cluster                 │  │ │
│  │  │  • Kubernetes: 1.28                                 │  │ │
│  │  │  • Node Pool: 2-5 nodes (auto-scale)                │  │ │
│  │  │  • VM Size: Standard_D2s_v3                         │  │ │
│  │  │  • Network: Azure CNI                               │  │ │
│  │  │  • AGIC: Enabled                                    │  │ │
│  │  │  • ACR Pull: Enabled                                │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  PostgreSQL: errorteam-postgres                     │  │ │
│  │  │  • SKU: B_Standard_B1ms                             │  │ │
│  │  │  • Storage: 32 GB                                   │  │ │
│  │  │  • Private Endpoint: Yes                            │  │ │
│  │  │  • Backup: 7 days                                   │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Log Analytics: errorteam-logs                      │  │ │
│  │  │  • Retention: 30 days                               │  │ │
│  │  │  • Container Insights: Enabled                      │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  │                                                           │ │
│  │  ┌─────────────────────────────────────────────────────┐  │ │
│  │  │  Application Insights: errorteam-appinsights        │  │ │
│  │  │  • Linked to Log Analytics                          │  │ │
│  │  │  • APM for Backend                                  │  │ │
│  │  └─────────────────────────────────────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### 1. User Request Flow (via AGIC)

```
User Browser
     │
     │ HTTP/HTTPS
     ▼
Application Gateway (Public IP)
     │
     │ AGIC routes based on path
     │
     ├──► /api/* ──────► Backend Service ──► Backend Pods
     │                        │                    │
     │                        │                    ▼
     │                        │              PostgreSQL
     │
     └──► /* ──────────► Frontend Service ──► Frontend Pods
                              │
                              └──► Calls /api/* (internal)
```

### 2. AGIC Configuration Flow

```
Developer creates/updates Ingress YAML
     │
     ▼
kubectl apply -f ingress.yaml
     │
     ▼
Kubernetes API Server
     │
     ▼
AGIC Pod (watches Ingress resources)
     │
     ▼
AGIC calls Azure API
     │
     ▼
Application Gateway automatically configured
     │
     ├──► Backend Pools updated
     ├──► Health Probes created
     ├──► Routing Rules applied
     └──► SSL/TLS configured
```

### 3. Monitoring Data Flow

```
Application Pods (Frontend & Backend)
     │
     │ Expose /metrics endpoint
     │
     ▼
Prometheus (scrapes every 15s)
     │
     │ Stores in TSDB (15 days retention)
     │
     ▼
Grafana queries Prometheus
     │
     │ Renders dashboards
     │
     ▼
User accesses Grafana via:
     ├──► Port Forward (localhost:3000)
     └──► AGIC Ingress (grafana.errorteam.com)
```

### 4. CI/CD Pipeline Flow

```
Developer pushes code
     │
     ▼
GitHub Actions triggered
     │
     ├──► PR: Build + Test + Validate
     │         └──► Terraform Plan (comment on PR)
     │
     └──► Merge to main:
           │
           ├──► Build Docker images
           │         │
           │         ├──► Frontend (React/Vite)
           │         └──► Backend (Spring Boot)
           │
           ├──► Push to ACR
           │         │
           │         └──► errorteamacr.azurecr.io/errorteam-*:latest
           │
           ├──► Update K8s manifests
           │
           └──► Deploy to AKS
                 │
                 └──► Rolling update (zero downtime)
```

---

## 🔐 Security Architecture

### Network Security

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS (Port 443)
                         │ HTTP (Port 80)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Application Gateway (Public)                   │
│  • WAF Protection (optional)                                │
│  • DDoS Protection                                          │
│  • SSL/TLS Termination                                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Private IP
                         │
┌─────────────────────────▼───────────────────────────────────┐
│              Virtual Network (10.1.0.0/16)                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  App Gateway Subnet (10.1.17.0/24)                  │   │
│  │  • NSG: Allow 65200-65535 (Gateway Manager)         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AKS Subnet (10.1.0.0/20)                           │   │
│  │  • Network Policy: Calico                           │   │
│  │  • NSG: Internal communication                      │   │
│  │  • Pod-to-pod encryption                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Database Subnet (10.1.16.0/24)                     │   │
│  │  • Service Delegation: PostgreSQL                   │   │
│  │  • NSG: Only from AKS subnet                        │   │
│  │  • Private Endpoint only                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Identity & Access Management

```
┌─────────────────────────────────────────────────────────────┐
│                   Azure Active Directory                    │
└────────────┬────────────────────────────────────────────────┘
             │
             ├──► Service Principal (Terraform)
             │    • Owner on errorteam-final-solution
             │    • Contributor on errorteam-final-infra
             │    • Contributor on errorteam-tfstate
             │
             ├──► AKS Managed Identity
             │    • AcrPull on errorteamacr
             │    • Network Contributor on VNet
             │    • Contributor on App Gateway (for AGIC)
             │
             └──► AGIC Managed Identity
                  • Read Ingress resources
                  • Write to App Gateway
```

### Secrets Management

```
Secrets stored in:
┌─────────────────────────────────────────────────────────────┐
│  1. Azure Key Vault (optional, not yet configured)          │
│     • Database passwords                                    │
│     • ACR credentials                                       │
│     • SSL certificates                                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  2. Kubernetes Secrets (base64 encoded)                     │
│     • db-credentials                                        │
│     • acr-secret (docker-registry)                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  3. Terraform State (encrypted at rest)                     │
│     • Storage Account: AES-256 encryption                   │
│     • Access via storage account keys                       │
│     • State locking with blob lease                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Monitoring Architecture

### Metrics Collection

```
┌─────────────────────────────────────────────────────────────┐
│                    Metrics Sources                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Application Metrics:                                       │
│  ├──► Backend: /actuator/prometheus (Spring Boot)          │
│  ├──► Frontend: nginx metrics                              │
│  └──► Custom app metrics                                   │
│                                                             │
│  Infrastructure Metrics:                                    │
│  ├──► Kubernetes API Server                                │
│  ├──► Kubelet (node metrics)                               │
│  ├──► cAdvisor (container metrics)                         │
│  └──► kube-state-metrics (K8s objects)                     │
│                                                             │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ Scrape every 15s
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   Prometheus                                │
│  • Time Series Database                                     │
│  • 15-day retention                                         │
│  • PromQL query language                                    │
│  • Alert rules (future)                                     │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ PromQL queries
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Grafana                                  │
│  • Dashboards:                                              │
│    ├──► Kubernetes Cluster                                 │
│    └──► BurgerBuilder Application                          │
│  • Alerts (email, Slack, etc.)                             │
│  • User authentication                                      │
└─────────────────────────────────────────────────────────────┘
```

### Dual Monitoring Strategy

```
┌──────────────────────────────────┬──────────────────────────────┐
│      Prometheus + Grafana        │     Azure Monitor            │
│       (In-cluster)               │       (Cloud-native)         │
├──────────────────────────────────┼──────────────────────────────┤
│                                  │                              │
│  ✓ Real-time metrics            │  ✓ Long-term storage         │
│  ✓ Custom dashboards            │  ✓ Azure integration         │
│  ✓ Application metrics          │  ✓ Compliance & audit        │
│  ✓ Free (self-hosted)           │  ✓ Multi-region              │
│  ✓ Full control                 │  ✓ Managed service           │
│                                  │                              │
│  Use for:                        │  Use for:                    │
│  • Developer debugging           │  • Production monitoring     │
│  • Application profiling         │  • Alerting & on-call        │
│  • Short-term analysis           │  • Compliance reports        │
│  • Cost tracking                 │  • Cross-service correlation │
│                                  │                              │
└──────────────────────────────────┴──────────────────────────────┘
```

---

## 🎯 High Availability & Scalability

### Application Tier

```
Frontend: 2 replicas (auto-scale ready)
     ├──► CPU threshold: 70%
     ├──► Memory threshold: 80%
     └──► Min: 2, Max: 10 pods

Backend: 2 replicas (auto-scale ready)
     ├──► CPU threshold: 70%
     ├──► Memory threshold: 80%
     └──► Min: 2, Max: 10 pods

Load Balancing:
     └──► Application Gateway
          ├──► Session affinity: Optional
          ├──► Connection draining: 30s
          └──► Health checks: Every 30s
```

### Infrastructure Tier

```
AKS Cluster:
     ├──► Node pool: 2-5 nodes (auto-scale)
     ├──► VM Size: Standard_D2s_v3
     ├──► Availability Zones: Can be enabled
     └──► Upgrade: Rolling (zero downtime)

Application Gateway:
     ├──► SKU: Standard_v2 (auto-scale ready)
     ├──► Capacity: 2 instances
     └──► Can scale to 125 instances

PostgreSQL:
     ├──► High Availability: Can be enabled
     ├──► Backup: 7 days
     └──► Point-in-time restore: Yes
```

---

## 🚀 Deployment Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│  • Source code                                              │
│  • Terraform files                                          │
│  • K8s manifests                                            │
│  • GitHub Actions workflows                                 │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ On PR
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              PR Validation Workflow                         │
│  ├──► Validate Terraform syntax                            │
│  ├──► Check for secrets in code                            │
│  ├──► Validate K8s manifests                               │
│  ├──► Run unit tests                                        │
│  └──► Terraform plan (post as comment)                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ On merge to main
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Deployment Workflow                            │
│                                                             │
│  Step 1: Build                                              │
│  ├──► Build frontend (npm build)                           │
│  ├──► Build backend (mvn package)                          │
│  └──► Run tests                                             │
│                                                             │
│  Step 2: Containerize                                       │
│  ├──► Build Docker image: frontend                         │
│  ├──► Build Docker image: backend                          │
│  └──► Tag with git SHA                                      │
│                                                             │
│  Step 3: Push                                               │
│  ├──► Push to ACR                                           │
│  └──► Push to Docker Hub (backup)                          │
│                                                             │
│  Step 4: Deploy Infrastructure (if changed)                 │
│  ├──► Terraform plan                                        │
│  └──► Terraform apply                                       │
│                                                             │
│  Step 5: Deploy Application                                 │
│  ├──► Update K8s deployments                               │
│  ├──► kubectl rollout status                               │
│  └──► Health check                                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Cost Estimate (Monthly - East US)

| Resource | SKU | Quantity | Est. Cost |
|----------|-----|----------|-----------|
| AKS Cluster | Free tier | 1 | $0 |
| VM Nodes | Standard_D2s_v3 | 2-5 | ~$140-$350 |
| Application Gateway | Standard_v2 | 2 instances | ~$280 |
| PostgreSQL | B_Standard_B1ms | 1 | ~$25 |
| Storage Account | Standard LRS | 1 | ~$2 |
| ACR | Basic | 1 | ~$5 |
| Log Analytics | Pay-as-you-go | - | ~$10-50 |
| Bandwidth | Outbound | - | ~$10-20 |
| **TOTAL** | | | **~$472-$742/month** |

**Savings Tips:**
- Use B-series VMs for non-production
- Enable auto-scaling (scale to 0 after hours)
- Use Azure Reserved Instances (up to 72% savings)
- Delete resources when not in use

---

## 📝 Next Steps

1. **Deploy Infrastructure**
   - Run setup-azure.sh
   - Initialize Terraform
   - Apply infrastructure

2. **Deploy Applications**
   - Push images to ACR
   - Deploy to AKS
   - Verify health

3. **Deploy Monitoring**
   - Run deploy-monitoring.sh
   - Access Grafana
   - View dashboards

4. **Configure DNS**
   - Point domain to App Gateway public IP
   - Update ingress hostnames
   - Enable SSL/TLS

5. **Production Hardening**
   - Change default passwords
   - Enable WAF
   - Configure backups
   - Set up alerting

---

**Error Team** | Complete Architecture | Azure AKS Infrastructure
Ready for production deployment! 🚀
