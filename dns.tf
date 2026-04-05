# --------------------------------------------------------------------------
# Azure DNS Zone (existing)
#
# References an Azure DNS zone that already exists for the reader's domain.
#
# The reader must have an Azure DNS zone set up before running Terraform.
# See the README for setup instructions.
# --------------------------------------------------------------------------

data "azurerm_dns_zone" "existing" {
  name                = var.domain_name
  resource_group_name = var.dns_resource_group_name
}

# --------------------------------------------------------------------------
# A Record: points the SonarQube hostname to the Application Gateway IP
# --------------------------------------------------------------------------

resource "azurerm_dns_a_record" "sonarqube" {
  name                = var.host_name
  zone_name           = data.azurerm_dns_zone.existing.name
  resource_group_name = var.dns_resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.appgw.ip_address]

  depends_on = [
    azurerm_kubernetes_cluster.sonarqube
  ]
}
