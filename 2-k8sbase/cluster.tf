module "eks-cluster" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v8.2.0"
  cluster_name = var.project_name
  subnets      = data.terraform_remote_state.networking.outputs.private_subnets
  vpc_id       = data.terraform_remote_state.networking.outputs.vpc_id
  manage_worker_autoscaling_policy = true
  manage_worker_iam_resources = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  workers_additional_policies = [
    aws_iam_policy.ssm_session_manager_access.arn
  ]

  worker_groups = [
    {
      name = "${var.project_name}_node_groups"
      instance_type = "t3a.medium"
      asg_max_size  = 2
      autoscaling_enabled = true
      protect_from_scale_in = true # Recommended by https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/autoscaling.md

      # public_ip = false
      key_name = ""
      tags = [{
        key                 = "Name"
        value               = "${var.project_name}-nodes"
        propagate_at_launch = true
      }]
      additional_security_group_ids = [
        aws_security_group.EFS_client.id
      ]
    }
  ]

  tags = {
    environment = "test"
  }

  write_kubeconfig    = true
  config_output_path  = "../kubeconfig"
  # map_roles = var.map_roles
}

# variable "map_roles" {
#   description = "Additional IAM roles to add to the aws-auth configmap."
#   type = list(object({
#     rolearn  = string
#     username = string
#     groups   = list(string)
#   }))

#   default = [
#     {
#       rolearn  = "arn:aws:iam::66666666666:role/role1"
#       username = "role1"
#       groups   = ["system:masters"]
#     },
#   ]
# }


resource "aws_iam_policy" "ssm_session_manager_access" {
  name        = "ssm_session_manager_access"
  path        = "/"
  description = "Enable workers to be used by SSM Session Manager"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_security_group" "EFS_client" {
  name        = "${var.project_name}_EFS_client"
  description = "Allow EFS outbound traffic"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
}

# TODO: Not sure this is necessary anymore:

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