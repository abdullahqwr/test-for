# Error Team - Terraform Root Outputs

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "aks_kube_config" {
  description = "Kubernetes configuration for kubectl"
  value       = module.aks.kube_config
  sensitive   = true
}

output "aks_host" {
  description = "AKS cluster API server endpoint"
  value       = module.aks.host
  sensitive   = true
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.networking.vnet_id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.networking.aks_subnet_id
}

output "db_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = module.database.server_fqdn
}

output "db_connection_string" {
  description = "PostgreSQL connection string"
  value       = module.database.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.app_insights_instrumentation_key
  sensitive   = true
}

output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = module.app_gateway.public_ip_address
}

output "resource_group_name" {
  description = "Name of the solution resource group"
  value       = data.azurerm_resource_group.solution.name
}

output "resource_group_location" {
  description = "Location of the solution resource group"
  value       = data.azurerm_resource_group.solution.location
}
