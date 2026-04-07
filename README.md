# SonarQube Server Enterprise Edition - Azure AKS Installation

This repository contains Terraform templates for deploying SonarQube Server Enterprise Edition on Azure Kubernetes Service (AKS).

## Infrastructure Components

| Component | Azure Service |
|-----------|--------------|
| Container Orchestration | Azure Kubernetes Service (AKS) |
| Database | Azure Database for PostgreSQL Flexible Server (v16, zone-redundant HA, private VNet access) |
| HTTPS / Ingress | Azure Application Gateway (Standard_v2) |
| TLS Certificate | Let's Encrypt via ACME - issued and renewed automatically |
| Networking | Azure Virtual Network |
| DNS | Azure DNS |
| Monitoring | Azure Log Analytics + Application Insights |
| Persistent Storage | Azure Managed Disk (managed-csi) |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) authenticated (`az login`)
- A SonarQube Server Enterprise Edition license key
- A registered domain with an Azure DNS zone for SSL certificate and routing

## Quick Start

```bash
# Edit terraform.tfvars.json with your specific values
cp terraform.tfvars.json.example terraform.tfvars.json

# Run Terraform commands
terraform init
terraform plan
terraform apply
```

Access SonarQube at `https://sonarqube.<your-domain>` 
Default login: `admin` / `admin` (change immediately)

> **Certificate management is fully automated.** Terraform requests, validates, and installs a trusted Let's Encrypt certificate as part of `terraform apply`. No manual certificate steps are required - provide your domain and email, and the rest is handled automatically.

## Configuration Values

Copy `terraform.tfvars.json.example` into `terraform.tfvars.json` and update the specific values for your environment:

```json
{
  "resource_group_name": "my-sonarqube-rg",
  "location": "eastus",
  "environment": "Production",

  "vnet_cidr": "10.0.0.0/16",
  "aks_subnet_cidr": "10.0.1.0/24",
  "appgw_subnet_cidr": "10.0.2.0/24",
  "postgresql_subnet_cidr": "10.0.3.0/28",

  "acme_email": "your-email@example.com",
  "domain_name": "your-domain.com",
  "dns_resource_group_name": "your-dns-resource-group",
  "host_name": "sonarqube",

  "cluster_name": "my-sonarqube-cluster",
  "kubernetes_version": "1.35",
  "system_node_vm_size": "Standard_D2s_v5",
  "node_vm_size": "Standard_D8ds_v5",
  "sonarqube_node_count": 1,

  "postgresql_server_name": "my-sonarqube-pg",
  "db_name": "sonarqube",
  "db_username": "sqadmin",
  "postgresql_sku": "GP_Standard_D4ds_v4",
  "postgresql_version": "16",
  "postgresql_storage_mb": 131072,

  "sonarqube_chart_version": "",
  "sonarqube_namespace": "sonarqube"
}
```

**Notes:**
- Subnet CIDRs must not overlap with existing VNets in your Azure environment
- `postgresql_subnet_cidr` requires a minimum /28 block
- `sonarqube_node_count` - defaults to `1`. Node pools can scale to multiple nodes, but SonarQube Server Enterprise Edition runs as a single-replica StatefulSet so one dedicated node is the correct setup for this deployment.
- `sonarqube_chart_version` - leave empty for latest, or pin for reproducibility (e.g. `"2026.2.1"`)
- `acme_server_url` is not shown above but can be added to switch certificate authorities. Default: Let's Encrypt production (`https://acme-v02.api.letsencrypt.org/directory`). Use the staging URL (`https://acme-staging-v02.api.letsencrypt.org/directory`) for testing to avoid rate limits.

## Configuration Files

| File | Description |
|------|-------------|
| `main.tf` | Providers and resource group |
| `network.tf` | VNet, subnets, public IPs |
| `aks.tf` | AKS cluster, system node pool, dedicated SonarQube node pool |
| `postgresql.tf` | PostgreSQL Flexible Server with zone-redundant HA, database, private DNS |
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
| System Node Pool | `system` (Standard_D2s_v5, 1 node) |
| SonarQube Node Pool | `sonarqube` (Standard_D8ds_v5, 1 node, tainted) |
| Application Gateway | `<cluster_name>-appgw` |
| PostgreSQL Flexible Server | `<postgresql_server_name>` (v16, zone-redundant HA, private VNet access) |
| PostgreSQL Database | `sonarqube` |
| TLS Certificate | `<host_name>.<domain_name>` (Let's Encrypt, auto-renewed) |
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
