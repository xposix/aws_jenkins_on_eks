module "eks-cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v7.0.0"
  cluster_name = "mytests"
  subnets      = "${module.vpc.private_subnets}"
  vpc_id       = "${module.vpc.vpc_id}"

  worker_groups = [
    {
      instance_type = "t3.large"
      asg_max_size  = 2
      autoscaling_enabled = true
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
