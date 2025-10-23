# Error Team - Application Gateway Module Variables

variable "gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for Application Gateway"
  type        = string
}

variable "backend_address_pool_name" {
  description = "Name of the backend address pool"
  type        = string
  default     = "default-backend-pool"
}

variable "frontend_port" {
  description = "Frontend HTTP port"
  type        = number
  default     = 80
}

variable "frontend_port_https" {
  description = "Frontend HTTPS port"
  type        = number
  default     = 443
}

variable "sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "SKU tier for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "capacity" {
  description = "Capacity (instance count) for Application Gateway"
  type        = number
  default     = 2
}

variable "enable_waf" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
