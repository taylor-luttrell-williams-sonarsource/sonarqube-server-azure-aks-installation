# SonarQube Server Enterprise — Azure AKS Installation

Terraform templates for deploying SonarQube Server Enterprise Edition on Azure Kubernetes Service (AKS).

## Infrastructure

| Component | Azure Service |
|-----------|--------------|
| Container Orchestration | Azure Kubernetes Service (AKS) |
| Database | Azure Database for PostgreSQL Flexible Server (v16, zone-redundant HA, private VNet access) |
| HTTPS / Ingress | Azure Application Gateway (Standard_v2) |
| TLS Certificate | Let's Encrypt via ACME — issued and renewed automatically |
| Networking | Azure Virtual Network |
| DNS | Azure DNS |
| Monitoring | Azure Log Analytics + Application Insights |
| Persistent Storage | Azure Managed Disk (managed-csi) |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) authenticated (`az login`)
- An Azure subscription
- A SonarQube Server Enterprise Edition license key
- A registered domain with an Azure DNS zone for SSL certificate and routing

## Quick Start

```bash
cp terraform.tfvars.json.example terraform.tfvars.json
# Edit terraform.tfvars.json with your values

terraform init
terraform plan
terraform apply
```

Access SonarQube at `https://sonarqube.<your-domain>`. Default login: `admin` / `admin`.

> **Certificate management is fully automated.** Terraform requests, validates, and installs a trusted Let's Encrypt certificate as part of `terraform apply`. No manual certificate steps are required — provide your domain and email, and the rest is handled automatically.

## Configuration

Copy `terraform.tfvars.json.example` to `terraform.tfvars.json` and update the values for your environment:

### Required Variables

```json
{
  "resource_group_name": "my-sonarqube-rg",
  "location": "eastus",
  "environment": "Production",
  "acme_email": "your-email@example.com",
  "cluster_name": "my-sonarqube-cluster",
  "kubernetes_version": "1.32",
  "node_vm_size": "Standard_D8ds_v5",
  "postgresql_server_name": "my-sonarqube-pg",
  "db_name": "sonarqube",
  "db_username": "sqadmin",
  "domain_name": "your-domain.com",
  "dns_resource_group_name": "your-dns-resource-group"
}
```

### Optional Variables

- `acme_server_url` — ACME directory URL for the certificate authority. Default: `"https://acme-v02.api.letsencrypt.org/directory"` (Let's Encrypt production). Use `"https://acme-staging-v02.api.letsencrypt.org/directory"` for testing to avoid rate limits.
- `host_name` — Hostname prefix for the SonarQube URL (`host_name.domain_name`). Default: `"sonarqube"`
- `system_node_vm_size` — VM SKU for the system node pool. Default: `"Standard_D2s_v5"`
- `sonarqube_node_count` — Number of nodes in the SonarQube pool. Default: `1`
- `postgresql_sku` — PostgreSQL compute tier. Default: `"GP_Standard_D4ds_v4"`
- `postgresql_version` — PostgreSQL major version. Default: `"16"`
- `postgresql_storage_mb` — PostgreSQL storage in MB. Default: `131072` (128 GB)
- `sonarqube_chart_version` — SonarQube Helm chart version. Leave empty for latest, or pin for production (e.g., `"2026.2.1"`)
- `sonarqube_namespace` — Kubernetes namespace for SonarQube. Default: `"sonarqube"`
- `vnet_cidr` — VNet address space. Default: `"10.0.0.0/16"`
- `aks_subnet_cidr` — AKS subnet CIDR. Default: `"10.0.1.0/24"`
- `appgw_subnet_cidr` — Application Gateway subnet CIDR. Default: `"10.0.2.0/24"`
- `postgresql_subnet_cidr` — PostgreSQL delegated subnet CIDR (minimum /28). Default: `"10.0.3.0/28"`

## Terraform Files

| File | Description |
|------|-------------|
| `main.tf` | Providers and resource group |
| `network.tf` | VNet, subnets, public IPs |
| `aks.tf` | AKS cluster, system node pool, dedicated SonarQube node pool |
| `postgresql.tf` | PostgreSQL Flexible Server with zone-redundant HA, database |
| `tls.tf` | ACME registration and certificate issuance via DNS-01 challenge |
| `appgateway.tf` | Application Gateway with HTTPS, ACME certificate, backend routing |
| `dns.tf` | DNS A record in the existing Azure DNS zone |
| `monitoring.tf` | Log Analytics workspace, Application Insights |
| `sonarqube.tf` | Kubernetes namespace, secrets, SonarQube Helm release |
| `sonarqube-values.yaml` | Helm chart values |
| `variables.tf` | Variable definitions |
| `outputs.tf` | Access URLs, resource names, monitoring IDs |

## Resources Created

| Resource | Name |
|----------|------|
| Resource Group | `<resource_group_name>` |
| Virtual Network + Subnets | `<cluster_name>-vnet` (AKS, App Gateway, PostgreSQL) |
| AKS Cluster | `<cluster_name>` |
| SonarQube Node Pool | `sonarqube` (Standard_D8ds_v5, tainted) |
| Application Gateway | `<cluster_name>-appgw` |
| PostgreSQL Flexible Server | `<postgresql_server_name>` (v16, zone-redundant HA, private VNet access) |
| PostgreSQL Database | `sonarqube` |
| TLS Certificate | `sonarqube.<domain_name>` (Let's Encrypt, auto-renewed) |
| DNS A Record | `<host_name>.<domain_name>` |
| Log Analytics Workspace | `<cluster_name>-logs` |
| Application Insights | `<cluster_name>-appinsights` |
| Helm Release | `sonarqube` (Enterprise Edition) |

## Upgrade

Update `sonarqube_chart_version` in `terraform.tfvars.json` and run `terraform apply`.

## Cleanup

```bash
terraform destroy
```
