resource "helm_release" "jenkins" {
  name      = "myjenkins"
  chart     = "stable/jenkins"
  namespace = "development"

  set {
    name  = "master.image"
    value = "jenkins/jenkins:lts-alpine"
  }

  set {
    name  = "master.imagePullPolicy"
    value = "Always"
  }

  set {
    name  = "master.resources"
    value = "{requests: {cpu: 50m, memory: 256Mi}, limits: {cpu: 2000m, memory: 4096Mi}}"
  }

  set {
    name  = "master.loadBalancerSourceRanges"
    value = "77.97.149.36/32, 89.89.89.89/32"
  }

  set {
    name  = "master.ingress.enabled"
    value = "true"
  }

  set {
    name  = "master.JCasC.enabled"
    value = "true"
  }

  set {
    name  = "master.sidecars.configAutoReload.enabled"
    value = "true"
  }

  set {
    name  = "master.installPlugins"
    value = "kubernetes:1.18.2 workflow-aggregator:2.6 credentials-binding:1.19 git:3.11.0 workflow-job:2.33 blueocean"
  }

  set {
    name  = "persistence.accessMode"
    value = "ReadWriteMany"
  }

  set {
    name  = "persistence.size"
    value = "20Gi"
  }

  set {
    name  = "persistence.subPath"
    value = "/jenkins"
  }
}
