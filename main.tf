provider "kubernetes" { config_path = var.kubeconfig_path }

resource "kubernetes_namespace_v1" "oficina" {
  metadata { name = var.namespace }
}
