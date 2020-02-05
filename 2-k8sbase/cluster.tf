locals {
  pre_userdata = <<USERDATA
  sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm 
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl start amazon-ssm-agent
USERDATA
}

module "eks-cluster" {
  source                           = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v8.2.0"
  cluster_name                     = var.project_tags.project_name
  subnets                          = data.terraform_remote_state.networking.outputs.private_subnets
  vpc_id                           = data.terraform_remote_state.networking.outputs.vpc_id
  manage_worker_autoscaling_policy = true
  manage_worker_iam_resources      = true

  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  workers_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  workers_group_defaults = {
    pre_userdata = local.pre_userdata
    public_ip    = false
  }

  worker_groups = [
    {
      name                 = "${var.project_tags.project_name}_node_groups"
      instance_type        = "t3a.medium"
      autoscaling_enabled  = true
      asg_min_size         = 1
      asg_desired_capacity = 1
      asg_max_size         = 2
      root_volume_size     = 100
      key_name             = var.bastion_pem_key
      enable_monitoring    = true
      tags = [{
        key                 = "Name"
        value               = "${var.project_tags.project_name}-eksnodes"
        propagate_at_launch = true
      }]
      additional_security_group_ids = [
        aws_security_group.EFS_client.id
      ]
    }
  ]

  tags = var.project_tags

  write_kubeconfig   = true
  config_output_path = "../kubeconfig"
  # map_roles = var.map_roles
}

# THIS CAN BE PASSED ON var TOO
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

resource "null_resource" "subnet_tags" {
  triggers = {
    cluster_id     = module.eks-cluster.cluster_id
    public_subnets = join(" ", data.terraform_remote_state.networking.outputs.public_subnets.*)
    timestamp      = timestamp()
  }
  count = length(data.terraform_remote_state.networking.outputs.public_subnets)
  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${self.triggers.public_subnets} --tags Key=kubernetes.io/cluster/${self.triggers.cluster_id},Value='shared'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 delete-tags --resources ${self.triggers.public_subnets} --tags Key=kubernetes.io/cluster/${self.triggers.cluster_id},Value='shared'"
  }
}

resource "aws_security_group" "EFS_client" {
  name        = "${var.project_tags.project_name}_EFS_client"
  description = "Allow EFS outbound traffic"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
}


module "eks-efs" {
  source                 = "./modules/eks-efs"
  project_tags           = var.project_tags
  subnet_ids             = data.terraform_remote_state.networking.outputs.private_subnets
  client_sg              = aws_security_group.EFS_client.id
  vpc_id                 = data.terraform_remote_state.networking.outputs.vpc_id
  enable_efs_integration = var.enable_efs_integration
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
