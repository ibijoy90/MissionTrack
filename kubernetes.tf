provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "missiontrack" {
  metadata {
    name = "missiontrack-tf"
  }
}

resource "kubernetes_service_account" "frontend" {
  metadata {
    name      = "frontend-sa-tf"
    namespace = kubernetes_namespace.missiontrack.metadata[0].name
  }
}

resource "kubernetes_deployment_v1" "nginx" {

  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.missiontrack.metadata[0].name

    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {

      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {

        service_account_name = kubernetes_service_account.frontend.metadata[0].name

        container {

          name  = "nginx"
          image = "nginxinc/nginx-unprivileged"

          port {
            container_port = 8080
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }

            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }

            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }

            initial_delay_seconds = 15
            period_seconds        = 20
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.missiontrack.metadata[0].name
  }

  spec {

    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "nginx" {

  metadata {
    name      = "nginx-ingress"
    namespace = kubernetes_namespace.missiontrack.metadata[0].name
  }

  spec {

    ingress_class_name = "nginx"

    tls {
      hosts       = ["nginx-tf.local"]
      secret_name = "nginx-tls-secret"
    }

    rule {
      host = "nginx-tf.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.nginx.metadata[0].name

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {

  metadata {
    name      = "nginx-hpa"
    namespace = kubernetes_namespace.missiontrack.metadata[0].name
  }

  spec {

    min_replicas = 3
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.nginx.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
