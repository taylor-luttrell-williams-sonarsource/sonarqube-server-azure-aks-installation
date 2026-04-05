# --------------------------------------------------------------------------
# Log Analytics Workspace
#
# Central log sink for AKS container logs and metrics (via the OMS agent
# addon enabled in aks.tf). Platform-native alternative to self-hosted
# monitoring stacks.
# --------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "sonarqube" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------------------------------------
# Application Insights
#
# Provides application-level monitoring, request tracing, and performance
# analytics. Backed by the Log Analytics workspace above.
# --------------------------------------------------------------------------

resource "azurerm_application_insights" "sonarqube" {
  name                = "${var.cluster_name}-appinsights"
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name
  workspace_id        = azurerm_log_analytics_workspace.sonarqube.id
  application_type    = "web"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
