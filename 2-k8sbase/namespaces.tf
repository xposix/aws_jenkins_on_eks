resource "kubernetes_namespace" "k8sdashboard" {
  metadata {
    annotations = {
      name = "k8sdashboard"
    }

    labels = {
      mylabel = "label-value"
    }

    name = "k8sdashboard"
  }
}
