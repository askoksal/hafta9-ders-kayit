terraform {
  required_version = ">= 1.17.0, < 2.0.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.4.0"
    }
  }
}
provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = "docker-desktop"
}
resource "kubernetes_namespace_v1" "lab" {
  metadata {
    name = "hafta9"
    labels = {
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
      "app.kubernetes.io/part-of"          = "hafta9-lab"
    }
  }
}
