output "kubeconfig" {
  value         = module.eks-cluster.kubeconfig
#   description   = 
  sensitive     = false
}

output "path_to_kubeconfig" {
  value         = module.eks-cluster.kubeconfig_filename
#   description   = 
  sensitive     = false
}
