data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
  enable_irsa                      = true
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
      name                 = "${var.project_tags.project_name}_eksnode_groups"
      instance_type        = var.workers_instance_type
      autoscaling_enabled  = true
      asg_min_size         = 1
      asg_desired_capacity = 1
      asg_max_size         = 8
      root_volume_size     = 100
      key_name             = var.bastion_pem_key
      enable_monitoring    = true
      tags = [
        {
          key                 = "Name"
          value               = "${var.project_tags.project_name}-eksnodes"
          propagate_at_launch = true
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/enabled"
          "value"               = "true"
          "propagate_at_launch" = "false"
        },
        {
          "key"                 = "k8s.io/cluster-autoscaler/${var.project_tags.project_name}"
          "value"               = "true"
          "propagate_at_launch" = "false"
        }
      ]
      additional_security_group_ids = [
        aws_security_group.EFS_client.id
      ]
      sns_notification_topic_arn = var.sns_notification_topic_arn
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

### EFS MODULE
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


### K8s AUTOSCALER

locals {
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler"
}

resource "local_file" "deployment" {
  content = templatefile("${path.module}/kubeautoscaler-conf.yaml.tmpl", {
    account_id   = data.aws_caller_identity.current.account_id,
    region       = data.aws_region.current.name,
    cluster_name = module.eks-cluster.cluster_id
  })
  filename = "${path.module}/kubeautoscaler-conf.yaml"
}


module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> v2.6.0"
  create_role                   = true
  role_name                     = "cluster-autoscaler"
  provider_url                  = replace(module.eks-cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.cluster_autoscaler.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks-cluster.cluster_id}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks-cluster.cluster_id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}


### NOTIFICATIONS
resource "aws_autoscaling_notification" "autoscaling_notifications" {
  count = var.sns_notification_topic_arn != "" ? 1 : 0

  group_names = [
    "${module.eks-cluster.workers_asg_arns}"
  ]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]
  topic_arn = var.sns_notification_topic_arn
}


resource "aws_cloudwatch_metric_alarm" "ec2_instance_t_credits" {
  count               = var.sns_notification_topic_arn != "" && length(regex("^t[[:digit:]]", var.workers_instance_type)) > 0 ? 1 : 0
  alarm_name          = "t_credits"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = 50
  alarm_description   = "A t-instance running out of credits."
  alarm_actions = [
    var.sns_notification_topic_arn
  ]
  dimensions = {
    AutoScalingGroupName = module.eks-cluster.workers_asg_names[0]
  }
}
