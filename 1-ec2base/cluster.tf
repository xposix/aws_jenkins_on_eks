module "eks-cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks"
  cluster_name = "mytests"
  subnets      = "${module.vpc.private_subnets}"
  vpc_id       = "${module.vpc.vpc_id}"

  node_groups = [
    {
      name = "mytest_node_groups"
      instance_type = "t3.large"
      asg_max_size  = 2
      autoscaling_enabled = true
      public_ip = false
      key_name = "rubensancho"
      tags = [{
        key                 = "foo"
        value               = "bar"
        propagate_at_launch = true
      }]
    }
  ]

  tags = {
    environment = "test"
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks-cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}
