module "eks-cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks"
  cluster_name = "mytests"
  subnets      = data.terraform_remote_state.networking.outputs.private_subnets
  vpc_id       = data.terraform_remote_state.networking.outputs.vpc_id

  node_groups = [
    {
      name = "mytest_node_groups"
      instance_type = "t3.large"
      asg_max_size  = 2
      autoscaling_enabled = true
      # public_ip = false
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
