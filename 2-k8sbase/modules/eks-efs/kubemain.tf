resource "kubernetes_service_account" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  metadata {
    name = "efs-provisioner"
  }
}

resource "kubernetes_deployment" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  depends_on = [
    aws_efs_mount_target.efs_mts
  ]
  metadata {
    name = "efs-provisioner"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "efs-provisioner"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "efs-provisioner"
        }
      }

      spec {
        service_account_name            = kubernetes_service_account.efs-provisioner[0].metadata.0.name
        automount_service_account_token = true
        container {
          image = "quay.io/external_storage/efs-provisioner:latest"
          name  = "efs-provisioner"

          env {
            name  = "FILE_SYSTEM_ID"
            value = var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id
          }
          env {
            name  = "AWS_REGION"
            value = data.aws_region.current.name
          }

          env {
            name  = "DNS_NAME"
            value = ""
          }

          env {
            name  = "PROVISIONER_NAME"
            value = "example.com/aws-efs"
          }

          volume_mount {
            mount_path = "/persistentvolumes"
            name       = "pv-volume"
          }
        }
        volume {
          name = "pv-volume"
          nfs {
            server = "${var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id}.efs.${data.aws_region.current.name}.amazonaws.com"
            path   = "/"
          }
        }
      }
    }
  }
}

resource "kubernetes_storage_class" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  metadata {
    name = "aws-efs"
  }
  storage_provisioner = "example.com/aws-efs"
}

resource "kubernetes_persistent_volume_claim" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  depends_on = [
    kubernetes_deployment.efs-provisioner
  ]
  metadata {
    name = "efs"
    annotations = {
      "volume.beta.kubernetes.io/storage-class" = "aws-efs"
    }
  }
  spec {
    storage_class_name = "efs"
    access_modes       = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Mi"
      }
    }
  }
}

## Authorisation

resource "kubernetes_cluster_role" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  metadata {
    name = "efs-provisioner-runner"
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list", "watch", "create", "update", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  metadata {
    name = "run-efs-provisioner"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "efs-provisioner-runner"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-provisioner"
    namespace = "default"
  }
}


resource "kubernetes_role" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  metadata {
    name = "leader-locking-efs-provisioner"
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "efs-provisioner" {
  count = var.enable_efs_integration ? 1 : 0
  metadata {
    name      = "leader-locking-efs-provisioner"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.efs-provisioner[0].metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.efs-provisioner[0].metadata.0.name
    namespace = "default"
  }
}

