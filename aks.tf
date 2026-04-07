# --------------------------------------------------------------------------
# Azure Kubernetes Service (AKS) Cluster
#
# Uses OMS agent addon for Azure Monitor / Log Analytics integration.
# Application Gateway (appgateway.tf) handles HTTPS ingress separately.
# --------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "sonarqube" {
  name                = var.cluster_name
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name
  dns_prefix          = lower(replace(var.cluster_name, "/[^a-zA-Z0-9]/", ""))
  kubernetes_version  = var.kubernetes_version

  identity {
    type = "SystemAssigned"
  }

  # Small system node pool — runs only Kubernetes system pods.
  # SonarQube runs on the dedicated node pool defined below.
  default_node_pool {
    name                        = "system"
    node_count                  = 1
    vm_size                     = var.system_node_vm_size
    os_disk_size_gb             = 30
    vnet_subnet_id              = azurerm_subnet.aks.id
    temporary_name_for_rotation = "systemtmp"
    orchestrator_version        = var.kubernetes_version

    node_labels = {
      "nodepool" = "system"
    }
  }

  role_based_access_control_enabled = true

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }

  # --------------------------------------------------------------------------
  # OMS Agent; Azure Monitor Integration
  #
  # Sends container logs and metrics to the Log Analytics workspace.
  # --------------------------------------------------------------------------
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.sonarqube.id
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    azurerm_subnet.aks,
    azurerm_log_analytics_workspace.sonarqube
  ]
}

# --------------------------------------------------------------------------
# Dedicated SonarQube Node Pool
#
# Taint and label are applied by Terraform so they don't need to be set
# manually with kubectl. The Helm values.yaml contains matching tolerations
# and nodeSelector.
# --------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "sonarqube" {
  name                  = "sonarqube"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.sonarqube.id
  vm_size               = var.node_vm_size
  node_count            = var.sonarqube_node_count
  os_disk_size_gb       = 100
  vnet_subnet_id        = azurerm_subnet.aks.id
  orchestrator_version  = var.kubernetes_version

  node_labels = {
    "sonarqube" = "true"
  }

  node_taints = [
    "sonarqube=true:NoSchedule"
  ]

  tags = {
    Environment = var.environment
    Workload    = "SonarQube"
    ManagedBy   = "Terraform"
  }
}
