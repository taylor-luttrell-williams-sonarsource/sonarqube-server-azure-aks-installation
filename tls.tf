# --------------------------------------------------------------------------
# ACME Certificate Management
#
# Issues a trusted TLS certificate via the ACME protocol (Let's Encrypt
# by default). Validates domain ownership using a DNS-01 challenge against
# the existing Azure DNS zone, so no manual steps required.
#
# Provides a domain and Terraform handles the rest.
# --------------------------------------------------------------------------

# Private key for the ACME account registration
resource "tls_private_key" "acme_account" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register an account with the ACME certificate authority
resource "acme_registration" "sonarqube" {
  account_key_pem = tls_private_key.acme_account.private_key_pem
  email_address   = var.acme_email
}

# Request a trusted certificate via DNS-01 challenge.
# The ACME provider creates a temporary TXT record in the Azure DNS zone
# to prove domain ownership, then removes it after validation.
resource "acme_certificate" "sonarqube" {
  account_key_pem = acme_registration.sonarqube.account_key_pem
  common_name     = "${var.host_name}.${var.domain_name}"
  key_type        = "2048"

  dns_challenge {
    provider = "azuredns"
    config = {
      AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
      AZURE_RESOURCE_GROUP  = var.dns_resource_group_name
      AZURE_TENANT_ID       = data.azurerm_client_config.current.tenant_id
      AZURE_ENVIRONMENT     = "public"
    }
  }

  depends_on = [
    acme_registration.sonarqube,
    data.azurerm_dns_zone.existing
  ]
}
