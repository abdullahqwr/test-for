# Error Team - Application Gateway Module
# Configured for AGIC (Application Gateway Ingress Controller)

resource "azurerm_public_ip" "appgw" {
  name                = "${var.gateway_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "${var.gateway_name}-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "${var.gateway_name}-fe-port-http"
    port = 80
  }

  frontend_port {
    name = "${var.gateway_name}-fe-port-https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.gateway_name}-fe-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = var.backend_address_pool_name
  }

  backend_http_settings {
    name                  = "${var.gateway_name}-be-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "${var.gateway_name}-health-probe"
  }

  probe {
    name                                      = "${var.gateway_name}-health-probe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  http_listener {
    name                           = "${var.gateway_name}-http-listener"
    frontend_ip_configuration_name = "${var.gateway_name}-fe-ip"
    frontend_port_name             = "${var.gateway_name}-fe-port-http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${var.gateway_name}-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.gateway_name}-http-listener"
    backend_address_pool_name  = var.backend_address_pool_name
    backend_http_settings_name = "${var.gateway_name}-be-http-settings"
    priority                   = 100
  }

  # Enable Web Application Firewall (optional but recommended)
  dynamic "waf_configuration" {
    for_each = var.enable_waf ? [1] : []
    content {
      enabled          = true
      firewall_mode    = "Prevention"
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"
    }
  }

  tags = merge(
    var.tags,
    {
      "managed-by-agic" = "true"
      "component"       = "ingress"
    }
  )

  lifecycle {
    ignore_changes = [
      # AGIC will manage these dynamically
      backend_address_pool,
      backend_http_settings,
      probe,
      request_routing_rule,
      url_path_map,
      http_listener,
      tags["last-updated-by-agic"]
    ]
  }
}
