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
variable "image_ref" { type = string }
variable "replicas" {
  type    = number
  default = 1
}
variable "banner" {
  type    = string
  default = "Hafta 9 Ders Kayıt Hizmeti"
}
module "course_service" {
  source    = "../modules/course_service"
  namespace = "hafta9"
  image_ref = var.image_ref
  replicas  = var.replicas
  banner    = var.banner
}
