# Error Team - Terraform Root Variables

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "errorteam"
}

variable "solution_resource_group_name" {
  description = "Name of the existing solution resource group (created by setup script)"
  type        = string
  default     = "errorteam-final-solution"
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Team        = "Error Team"
    Project     = "BurgerBuilder"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# AKS Configuration
variable "aks_node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# Networking Configuration
variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "db_subnet_prefix" {
  description = "Address prefix for database subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "appgw_subnet_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.1.3.0/24"
}

# Database Configuration
variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "burgerbuilder"
}

variable "db_admin_username" {
  description = "Admin username for PostgreSQL"
  type        = string
  default     = "errorteamadmin"
}

variable "db_admin_password" {
  description = "Admin password for PostgreSQL"
  type        = string
  sensitive   = true
}

variable "db_sku_name" {
  description = "SKU name for PostgreSQL server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_storage_mb" {
  description = "Storage in MB for PostgreSQL server"
  type        = number
  default     = 32768
}
