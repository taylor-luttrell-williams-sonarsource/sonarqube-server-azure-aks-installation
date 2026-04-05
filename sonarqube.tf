# --------------------------------------------------------------------------
# Wait for AKS cluster to become fully ready before creating K8s resources.
# --------------------------------------------------------------------------

resource "time_sleep" "wait_for_cluster" {
  create_duration = "30s"

  depends_on = [
    azurerm_kubernetes_cluster.sonarqube,
    azurerm_kubernetes_cluster_node_pool.sonarqube
  ]
}

# --------------------------------------------------------------------------
# Kubernetes Namespace
# --------------------------------------------------------------------------

resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = var.sonarqube_namespace
  }

  depends_on = [time_sleep.wait_for_cluster]
}

# --------------------------------------------------------------------------
# Kubernetes Secrets
# --------------------------------------------------------------------------

resource "kubernetes_secret" "sonarqube_db_password" {
  metadata {
    name      = "sonarqube-aks-db-password"
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
  }

  data = {
    password = random_password.sonarqube_db_password.result
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.sonarqube]
}

resource "kubernetes_secret" "sonarqube_monitoring_password" {
  metadata {
    name      = "sonarqube-aks-monitoring-password"
    namespace = kubernetes_namespace.sonarqube.metadata[0].name
  }

  data = {
    password = random_password.sonarqube_monitoring_password.result
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.sonarqube]
}

# --------------------------------------------------------------------------
# SonarQube Helm Release
# --------------------------------------------------------------------------

resource "helm_release" "sonarqube" {
  name       = "sonarqube"
  repository = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart      = "sonarqube"
  namespace  = kubernetes_namespace.sonarqube.metadata[0].name
  version    = var.sonarqube_chart_version != "" ? var.sonarqube_chart_version : null

  # Base values from file + dynamic overlay
  values = [
    file("${path.module}/sonarqube-values.yaml"),

    yamlencode({
      # JDBC connection — wired to the Terraform-managed PostgreSQL server
      jdbcOverwrite = {
        enabled               = true
        jdbcUrl               = "jdbc:postgresql://${azurerm_postgresql_flexible_server.sonarqube.fqdn}:5432/${azurerm_postgresql_flexible_server_database.sonarqube.name}?sslmode=require&socketTimeout=1500"
        jdbcUsername          = var.db_username
        jdbcSecretName        = kubernetes_secret.sonarqube_db_password.metadata[0].name
        jdbcSecretPasswordKey = "password"
      }

      # Monitoring passcode — references the Terraform-managed secret
      monitoringPasscodeSecretName = kubernetes_secret.sonarqube_monitoring_password.metadata[0].name
      monitoringPasscodeSecretKey  = "password"

      # Service — LoadBalancer using a pre-created tagged public IP.
      # The IP is placed in the AKS node resource group where the cluster's
      # managed identity already has access (no role assignments needed).
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/azure-pip-name"                  = azurerm_public_ip.sonarqube_svc.name
          "service.beta.kubernetes.io/azure-load-balancer-resource-group" = azurerm_kubernetes_cluster.sonarqube.node_resource_group
        }
      }
    })
  ]

  wait          = true
  wait_for_jobs = true
  timeout       = 900

  depends_on = [
    time_sleep.wait_for_cluster,
    azurerm_postgresql_flexible_server_database.sonarqube,
    kubernetes_secret.sonarqube_db_password,
    kubernetes_secret.sonarqube_monitoring_password,
    azurerm_public_ip.sonarqube_svc
  ]
}
