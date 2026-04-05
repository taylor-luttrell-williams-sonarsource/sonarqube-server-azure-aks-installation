# --------------------------------------------------------------------------
# Virtual Network
#
# Three subnets share the VNet:
#   1. AKS nodes
#   2. Application Gateway
#   3. PostgreSQL Flexible Server (delegated, private access only)
# --------------------------------------------------------------------------

resource "azurerm_virtual_network" "sonarqube" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name
  address_space       = [var.vnet_cidr]

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------------------------------------
# AKS Subnet
# --------------------------------------------------------------------------

resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.sonarqube.name
  virtual_network_name = azurerm_virtual_network.sonarqube.name
  address_prefixes     = [var.aks_subnet_cidr]
}

# --------------------------------------------------------------------------
# PostgreSQL Subnet
#
# Delegated to Microsoft.DBforPostgreSQL/flexibleServers for VNet
# integration. PostgreSQL has no public endpoint so traffic stays entirely
# within the private network. Must be configured at server creation time.
# --------------------------------------------------------------------------

resource "azurerm_subnet" "postgresql" {
  name                 = "${var.cluster_name}-postgresql-subnet"
  resource_group_name  = azurerm_resource_group.sonarqube.name
  virtual_network_name = azurerm_virtual_network.sonarqube.name
  address_prefixes     = [var.postgresql_subnet_cidr]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# --------------------------------------------------------------------------
# Application Gateway Subnet
# --------------------------------------------------------------------------

resource "azurerm_subnet" "appgw" {
  name                 = "${var.cluster_name}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.sonarqube.name
  virtual_network_name = azurerm_virtual_network.sonarqube.name
  address_prefixes     = [var.appgw_subnet_cidr]
}

# --------------------------------------------------------------------------
# Application Gateway Public IP
# --------------------------------------------------------------------------

resource "azurerm_public_ip" "appgw" {
  name                = "${var.cluster_name}-appgw-pip"
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_resource_group.sonarqube.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------------------------------------
# SonarQube LoadBalancer Public IP
#
# Placed in the AKS node resource group (MC_...) where the cluster's
# managed identity already has Contributor access. This avoids any need
# for additional role assignments.
#
# AKS is directed to use this pre-created IP via service annotations in
# sonarqube.tf.
# --------------------------------------------------------------------------

resource "azurerm_public_ip" "sonarqube_svc" {
  name                = "${var.cluster_name}-sonarqube-svc-pip"
  location            = azurerm_resource_group.sonarqube.location
  resource_group_name = azurerm_kubernetes_cluster.sonarqube.node_resource_group
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [azurerm_kubernetes_cluster.sonarqube]
}
