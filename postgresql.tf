# --------------------------------------------------------------------------
# Random Passwords
# --------------------------------------------------------------------------

resource "random_password" "sonarqube_db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "sonarqube_monitoring_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# --------------------------------------------------------------------------
# Private DNS Zone
#
# Required for VNet integration. Allows the PostgreSQL server's private
# hostname to resolve correctly within the VNet.
# --------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.sonarqube.name

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${var.cluster_name}-postgresql-dns-link"
  resource_group_name   = azurerm_resource_group.sonarqube.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.sonarqube.id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------------------------------------
# Azure Database for PostgreSQL Flexible Server
#
# Deliberately kept separate from the AKS/ingress infrastructure so the
# database can survive a full cluster tear-down and rebuild. Customers
# upgrading SonarQube or scaling to larger VMs can destroy and recreate
# the AKS cluster without losing analysis history.
#
# VNet integration (delegated subnet + private DNS) ensures no public
# endpoint is exposed. Traffic between AKS and PostgreSQL stays entirely
# within the private network.
#
# Zone-redundant HA ensures automatic failover across availability zones.
# --------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server" "sonarqube" {
  name                          = var.postgresql_server_name
  location                      = azurerm_resource_group.sonarqube.location
  resource_group_name           = azurerm_resource_group.sonarqube.name
  version                       = var.postgresql_version
  administrator_login           = var.db_username
  administrator_password        = random_password.sonarqube_db_password.result
  sku_name                      = var.postgresql_sku
  storage_mb                    = var.postgresql_storage_mb
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  auto_grow_enabled             = true
  public_network_access_enabled = false
  zone                          = "1"

  delegated_subnet_id = azurerm_subnet.postgresql.id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql.id

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    azurerm_resource_group.sonarqube,
    azurerm_private_dns_zone_virtual_network_link.postgresql
  ]
}

# --------------------------------------------------------------------------
# SonarQube Database
# --------------------------------------------------------------------------

resource "azurerm_postgresql_flexible_server_database" "sonarqube" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.sonarqube.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}
