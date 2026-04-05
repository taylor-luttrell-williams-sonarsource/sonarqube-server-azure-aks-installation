# --------------------------------------------------------------------------
# Application Gateway
#
# Fully Terraform-managed.
# Terminates HTTPS on port 443, forwards plain HTTP to the SonarQube
# LoadBalancer service on port 9000. Redirects HTTP (port 80) to HTTPS.
# --------------------------------------------------------------------------

resource "azurerm_application_gateway" "sonarqube" {
  name                = "${var.cluster_name}-appgw"
  resource_group_name = azurerm_resource_group.sonarqube.name
  location            = azurerm_resource_group.sonarqube.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  # --------------------------------------------------------------------------
  # TLS Certificate (self-signed for POC)
  # --------------------------------------------------------------------------

  ssl_certificate {
    name     = "sonarqube-tls"
    data     = acme_certificate.sonarqube.certificate_p12
    password = acme_certificate.sonarqube.certificate_p12_password
  }

  # --------------------------------------------------------------------------
  # Frontend
  # --------------------------------------------------------------------------

  frontend_ip_configuration {
    name                 = "appgw-pip-config"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "port-443"
    port = 443
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  # --------------------------------------------------------------------------
  # Backend — SonarQube LoadBalancer IP on port 9000
  # --------------------------------------------------------------------------

  backend_address_pool {
    name         = "sonarqube-backend"
    ip_addresses = [azurerm_public_ip.sonarqube_svc.ip_address]
  }

  backend_http_settings {
    name                  = "sonarqube-backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 9000
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "sonarqube-health-probe"
  }

  probe {
    name                = "sonarqube-health-probe"
    protocol            = "Http"
    host                = azurerm_public_ip.sonarqube_svc.ip_address
    path                = "/api/system/status"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = ["200"]
    }
  }

  # --------------------------------------------------------------------------
  # Listeners
  # --------------------------------------------------------------------------

  http_listener {
    name                           = "sonarqube-https-listener"
    frontend_ip_configuration_name = "appgw-pip-config"
    frontend_port_name             = "port-443"
    protocol                       = "Https"
    ssl_certificate_name           = "sonarqube-tls"
  }

  http_listener {
    name                           = "sonarqube-http-listener"
    frontend_ip_configuration_name = "appgw-pip-config"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  # --------------------------------------------------------------------------
  # HTTP → HTTPS redirect
  # --------------------------------------------------------------------------

  redirect_configuration {
    name                 = "http-to-https-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "sonarqube-https-listener"
    include_path         = true
    include_query_string = true
  }

  # --------------------------------------------------------------------------
  # Routing Rules
  # --------------------------------------------------------------------------

  request_routing_rule {
    name                       = "sonarqube-https-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "sonarqube-https-listener"
    backend_address_pool_name  = "sonarqube-backend"
    backend_http_settings_name = "sonarqube-backend-settings"
  }

  request_routing_rule {
    name                        = "sonarqube-http-redirect-rule"
    rule_type                   = "Basic"
    priority                    = 200
    http_listener_name          = "sonarqube-http-listener"
    redirect_configuration_name = "http-to-https-redirect"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    azurerm_subnet.appgw,
    azurerm_public_ip.appgw,
    azurerm_public_ip.sonarqube_svc,
    acme_certificate.sonarqube
  ]
}
