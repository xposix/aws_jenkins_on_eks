variable "project_tags" {
  type        = map
  description = "A key/value map containing tags to add to all resources"
}

variable "workers_pem_key" {
  type        = string
  description = "PEM key for SSH access to the workers instances."
  default     = ""
}

variable "workers_instance_type" {
  type        = string
  description = "Instance type for the EKS workers"
}

variable "asg_min_size" {
  type        = number
  description = "Minimum number of instances in the workers autoscaling group."
}

variable "asg_max_size" {
  type        = number
  description = "Maximum number of instances in the workers autoscaling group."
}

variable "workers_root_volume_size" {
  type        = number
  description = "Size of the root volume desired for the EKS workers."
  default     = 100
}

variable "enable_eks_public_endpoint" {
  type        = bool
  description = "Whether to expose the EKS endpoint to the Internet."
}

variable "eks_public_access_cidrs" {
  type        = list(string)
  description = "List of IPs that have access to public endpoint."
  default     = ["0.0.0.0/0"]
}

variable "enable_eks_private_endpoint" {
  type        = bool
  description = "Whether to create an internal EKS endpoint for access from the VPC."
}

variable "enable_efs_integration" {
  type        = bool
  description = "Whether to deploy an EFS volume to provide support for ReadWriteMany volumes."
}

variable "existing_efs_volume" {
  description = "Volume ID of an existing EFS, used for Disaster Recovery purposes"
  type        = string
  default     = ""
}

variable "sns_notification_topic_arn" {
  description = "SNS notification topic to send alerts to Slack"
  type        = string
  default     = ""
}

