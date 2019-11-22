module "eks-cluster" {
  source = "./modules/terraform-aws-eks"
  cluster_name = "mytests"
  subnets      = "${vpc.private_subnets}"
  vpc_id       = "${vpc.vpc_id}"

  worker_groups = [
    {
      instance_type = "t3.large"
      asg_max_size  = 2
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
