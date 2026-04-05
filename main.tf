# --------------------------------------------------------------------------
# Terraform & Provider Configuration
# --------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0, < 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "acme" {
  server_url = var.acme_server_url
}

# Used to pass subscription and tenant credentials to the ACME DNS challenge
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.sonarqube.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.sonarqube.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.sonarqube.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.sonarqube.kube_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.sonarqube.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.sonarqube.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.sonarqube.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.sonarqube.kube_config[0].cluster_ca_certificate)
  }
}

# --------------------------------------------------------------------------
# Resource Group
# --------------------------------------------------------------------------

resource "azurerm_resource_group" "sonarqube" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
