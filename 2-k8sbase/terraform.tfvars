project_tags = {
  project_name = "test01"
  environment  = "test"
}

workers_instance_type = "t3a.medium"
asg_min_size          = 1
asg_max_size          = 4
workers_pem_key       = ""

enable_eks_private_endpoint = false
enable_eks_public_endpoint  = true
eks_public_access_cidrs     = ["0.0.0.0/0"]

enable_efs_integration = true
existing_efs_volume    = ""

sns_notification_topic_arn = ""
