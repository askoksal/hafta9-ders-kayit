variable "namespace" { type = string }
variable "image_ref" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.:-]*/[a-z0-9][a-z0-9_./-]*@sha256:[0-9a-f]{64}$", var.image_ref))
    error_message = "Kayıt deposu adresini tam sha256 digest ile belirtin; etiket kullanmayın."
  }
}
variable "replicas" {
  type    = number
  default = 1
  validation {
    condition     = contains([1, 2, 3], var.replicas)
    error_message = "Kopya sayısı 1, 2 veya 3 olmalıdır. Kayıt deneyi yalnız 1 kopyada yapılır."
  }
}
variable "banner" {
  type    = string
  default = "Hafta 9 Ders Kayıt Hizmeti"
}

resource "kubernetes_config_map_v1" "app" {
  metadata {
    name      = "ders-kayit-config"
    namespace = var.namespace
  }
  data = { COURSE_BANNER = var.banner }
}

resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = "ders-kayit"
    namespace = var.namespace
  }
  wait_for_rollout = true
  spec {
    replicas = var.replicas
    # Bellekteki verilerin kaybı beklenir; kesintisiz güncelleme iddiası yoktur.
    strategy { type = "Recreate" }
    selector { match_labels = { app = "ders-kayit" } }
    template {
      metadata {
        labels = { app = "ders-kayit" }
        # ConfigMap ortam değişkeni değişince Pod'un yeniden oluşturulmasını sağlar.
        annotations = { "hafta9/config-hash" = sha256(jsonencode(kubernetes_config_map_v1.app.data)) }
      }
      spec {
        automount_service_account_token = false
        security_context {
          run_as_non_root = true
          run_as_user     = 10001
          run_as_group    = 10001
          fs_group        = 10001
          seccomp_profile { type = "RuntimeDefault" }
        }
        container {
          name              = "web"
          image             = var.image_ref
          image_pull_policy = "IfNotPresent"
          port { container_port = 8080 }
          env {
            name = "COURSE_BANNER"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.app.metadata[0].name
                key  = "COURSE_BANNER"
              }
            }
          }
          env {
            name = "API_TOKEN"
            value_from {
              secret_key_ref {
                name = "ders-kayit-access"
                key  = "api-token"
              }
            }
          }
          resources {
            requests = { cpu = "100m", memory = "64Mi" }
            limits   = { cpu = "500m", memory = "128Mi" }
          }
          security_context {
            run_as_non_root            = true
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities { drop = ["ALL"] }
          }
          readiness_probe {
            http_get {
              path = "/readyz"
              port = 8080
            }
            initial_delay_seconds = 2
            period_seconds        = 3
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }
        volume {
          name = "tmp"
          empty_dir {
            medium     = "Memory"
            size_limit = "16Mi"
          }
        }
      }
    }
  }
  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "kubernetes_service_v1" "app" {
  metadata {
    name      = "ders-kayit"
    namespace = var.namespace
  }
  spec {
    selector = { app = "ders-kayit" }
    type     = "ClusterIP"
    port {
      port        = 80
      target_port = 8080
    }
  }
}

output "deployment_name" { value = kubernetes_deployment_v1.app.metadata[0].name }
