output "kubeconfig" {
  value       = module.eks-cluster.kubeconfig
  description = "Content of the kubeconfig file"
  sensitive   = false
}

output "path_to_kubeconfig" {
  value       = module.eks-cluster.kubeconfig_filename
  description = "Path to the created kubeconfig"
  sensitive   = false
}
