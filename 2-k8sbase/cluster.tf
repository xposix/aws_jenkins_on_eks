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
      worker_additional_security_group_ids = [
        aws_security_group.EFS_client
      ]
    }
  ]

  tags = {
    environment = "test"
  }
}

resource "aws_security_group" "EFS_client" {
  name        = "EFS_client"
  description = "Allow EFS outbound traffic"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
}