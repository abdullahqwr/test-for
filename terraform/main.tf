# Error Team - Terraform Root Configuration
# Azure Kubernetes Service Infrastructure

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  
  # Remote state backend in ISOLATED resource group
  backend "azurerm" {
    resource_group_name  = "errorteam-tfstate"    # ISOLATED RG for TF state
    storage_account_name = "errorteamtfstate"
    container_name       = "errorteam-tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = false  # Use access key authentication
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Data source for existing solution resource group
data "azurerm_resource_group" "solution" {
  name = var.solution_resource_group_name
}

# Application Gateway (must be created BEFORE AKS for AGIC)
module "app_gateway" {
  source = "./modules/app_gateway"
  
  resource_group_name = data.azurerm_resource_group.solution.name
  location           = data.azurerm_resource_group.solution.location
  gateway_name       = "${var.prefix}-appgw"
  
  subnet_id = module.networking.appgw_subnet_id
  
  backend_address_pool_name = "${var.prefix}-backend-pool"
  frontend_port            = 80
  frontend_port_https      = 443
  
  tags = var.tags
}

# AKS Module with AGIC enabled
module "aks" {
  source = "./modules/aks"
  
  resource_group_name = data.azurerm_resource_group.solution.name
  location           = data.azurerm_resource_group.solution.location
  cluster_name       = "${var.prefix}-aks-cluster"
  
  node_count          = var.aks_node_count
  node_vm_size        = var.aks_node_vm_size
  kubernetes_version  = var.kubernetes_version
  
  acr_id         = var.acr_id
  app_gateway_id = module.app_gateway.gateway_id  # Enable AGIC
  
  tags = var.tags
  
  depends_on = [module.app_gateway]
}

# Networking Module
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = data.azurerm_resource_group.solution.name
  location           = data.azurerm_resource_group.solution.location
  vnet_name          = "${var.prefix}-vnet"
  
  vnet_address_space      = var.vnet_address_space
  aks_subnet_prefix       = var.aks_subnet_prefix
  db_subnet_prefix        = var.db_subnet_prefix
  appgw_subnet_prefix     = var.appgw_subnet_prefix
  
  tags = var.tags
}

# Database Module (Azure Database for PostgreSQL)
module "database" {
  source = "./modules/database"
  
  resource_group_name = data.azurerm_resource_group.solution.name
  location           = data.azurerm_resource_group.solution.location
  server_name        = "${var.prefix}-postgres"
  
  db_subnet_id        = module.networking.db_subnet_id
  db_name             = var.db_name
  db_admin_username   = var.db_admin_username
  db_admin_password   = var.db_admin_password
  
  sku_name = var.db_sku_name
  storage_mb = var.db_storage_mb
  
  tags = var.tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  resource_group_name = data.azurerm_resource_group.solution.name
  location           = data.azurerm_resource_group.solution.location
  
  log_analytics_name = "${var.prefix}-logs"
  app_insights_name  = "${var.prefix}-appinsights"
  
  aks_cluster_id = module.aks.cluster_id
  
  tags = var.tags
}


