provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
}

provider "kubernetes" {
  config_path = "../aws_eks/kubeconfig"
}
