# --------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.sonarqube.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.sonarqube.name
}

output "aks_get_credentials_command" {
  description = "Run this command to configure kubectl for the AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.sonarqube.name} --name ${azurerm_kubernetes_cluster.sonarqube.name} --admin"
}

# --------------------------------------------------------------------------
# Database
# --------------------------------------------------------------------------

output "postgresql_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.sonarqube.fqdn
}

output "postgresql_database_name" {
  description = "Name of the SonarQube database"
  value       = azurerm_postgresql_flexible_server_database.sonarqube.name
}

# --------------------------------------------------------------------------
# Networking & Access
# --------------------------------------------------------------------------

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "sonarqube_url" {
  description = "HTTPS URL for the SonarQube instance"
  value       = "https://${var.host_name}.${var.domain_name}"
}

output "sonarqube_url_by_ip" {
  description = "Access SonarQube directly via the Application Gateway public IP"
  value       = "https://${azurerm_public_ip.appgw.ip_address}"
}

output "sonarqube_loadbalancer_ip" {
  description = "Direct SonarQube LoadBalancer IP (port 9000, HTTP — use the App Gateway URL for HTTPS)"
  value       = azurerm_public_ip.sonarqube_svc.ip_address
}

# --------------------------------------------------------------------------
# DNS
# --------------------------------------------------------------------------

output "dns_zone_nameservers" {
  description = "Nameservers for the Azure DNS zone (for reference — delegation should already be in place)"
  value       = data.azurerm_dns_zone.existing.name_servers
}

output "dns_record_fqdn" {
  description = "FQDN of the SonarQube DNS A record"
  value       = "${var.host_name}.${var.domain_name}"
}

# --------------------------------------------------------------------------
# Monitoring
# --------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for querying container logs"
  value       = azurerm_log_analytics_workspace.sonarqube.id
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.sonarqube.connection_string
  sensitive   = true
}

# --------------------------------------------------------------------------
# Helm
# --------------------------------------------------------------------------

output "sonarqube_namespace" {
  description = "Kubernetes namespace where SonarQube is deployed"
  value       = kubernetes_namespace.sonarqube.metadata[0].name
}

output "sonarqube_helm_status" {
  description = "Status of the SonarQube Helm release"
  value       = helm_release.sonarqube.status
}
