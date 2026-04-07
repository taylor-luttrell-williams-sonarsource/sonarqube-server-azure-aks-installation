# --------------------------------------------------------------------------
# Azure / General
# --------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment tag (e.g., Test, Staging, Production)"
  type        = string
  default     = "Production"
}


# --------------------------------------------------------------------------
# Networking
# --------------------------------------------------------------------------

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "appgw_subnet_cidr" {
  description = "CIDR block for the Application Gateway subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "postgresql_subnet_cidr" {
  description = "CIDR block for the PostgreSQL delegated subnet (minimum /28)"
  type        = string
  default     = "10.0.3.0/28"
}

# --------------------------------------------------------------------------
# DNS & TLS
# --------------------------------------------------------------------------

variable "acme_email" {
  description = "Email address for ACME certificate registration (used by Let's Encrypt for expiry notifications)"
  type        = string
}

variable "acme_server_url" {
  description = "ACME directory URL. Defaults to Let's Encrypt production. Use https://acme-staging-v02.api.letsencrypt.org/directory for testing."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "domain_name" {
  description = "Domain name with an existing Azure DNS zone (e.g., example.com)"
  type        = string
}

variable "dns_resource_group_name" {
  description = "Resource group containing the existing Azure DNS zone"
  type        = string
}

variable "host_name" {
  description = "Host name prefix for the SonarQube instance (e.g., sonarqube → sonarqube.example.com)"
  type        = string
  default     = "sonarqube"
}

# --------------------------------------------------------------------------
# AKS Cluster
# --------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 63
    error_message = "The cluster_name must be between 1 and 63 characters."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.35"
}

variable "system_node_vm_size" {
  description = "VM size for the default system node pool"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "node_vm_size" {
  description = "VM size for the SonarQube node pool (min 8 cores / 16 GB for Enterprise)"
  type        = string
  default     = "Standard_D8ds_v5"
}

variable "sonarqube_node_count" {
  description = "Number of nodes in the SonarQube node pool"
  type        = number
  default     = 1
}

# --------------------------------------------------------------------------
# PostgreSQL
# --------------------------------------------------------------------------

variable "postgresql_server_name" {
  description = "Globally unique name for the PostgreSQL Flexible Server"
  type        = string
}

variable "db_name" {
  description = "Name of the SonarQube database"
  type        = string
  default     = "sonarqube"
}

variable "db_username" {
  description = "Admin username for PostgreSQL"
  type        = string
  default     = "sqadmin"
}

variable "postgresql_sku" {
  description = "SKU for the PostgreSQL Flexible Server"
  type        = string
  default     = "GP_Standard_D4ds_v4"
}

variable "postgresql_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "postgresql_storage_mb" {
  description = "Storage size in MB for PostgreSQL (128 GB = 131072)"
  type        = number
  default     = 131072
}

# --------------------------------------------------------------------------
# SonarQube
# --------------------------------------------------------------------------

variable "sonarqube_chart_version" {
  description = "Version of the SonarQube Helm chart. Leave empty for latest."
  type        = string
  default     = ""
}

variable "sonarqube_namespace" {
  description = "Kubernetes namespace for SonarQube"
  type        = string
  default     = "sonarqube"
}
