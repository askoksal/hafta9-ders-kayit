mock_provider "kubernetes" {}

variables {
  namespace = "hafta9"
  image_ref = "ghcr.io/test/hafta9-ders-kayit@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}

run "restricted_single_replica" {
  command = plan
  assert {
    condition     = tonumber(kubernetes_deployment_v1.app.spec[0].replicas) == 1
    error_message = "Temel kayıt senaryosu tek kopya olmalıdır."
  }
  assert {
    condition     = kubernetes_service_v1.app.spec[0].type == "ClusterIP"
    error_message = "Dış yük dengeleyici açılmamalıdır."
  }
  assert {
    condition     = kubernetes_deployment_v1.app.spec[0].template[0].spec[0].container[0].security_context[0].read_only_root_filesystem
    error_message = "Salt okunur kök dosya sistemi gereklidir."
  }
  assert {
    condition     = kubernetes_deployment_v1.app.spec[0].template[0].spec[0].automount_service_account_token == false
    error_message = "Uygulamaya küme erişim belirteci bağlanmamalıdır."
  }
}

run "reject_mutable_tag" {
  command = plan
  variables { image_ref = "ghcr.io/test/hafta9-ders-kayit:latest" }
  expect_failures = [var.image_ref]
}

run "reject_unbounded_scaling" {
  command = plan
  variables { replicas = 10 }
  expect_failures = [var.replicas]
}
