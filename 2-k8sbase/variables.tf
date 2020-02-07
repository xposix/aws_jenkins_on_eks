variable "project_tags" {
  type        = map
  description = "A key/value map containing tags to add to all resources"
}

variable "bastion_pem_key" {
  type = string
}

variable "workers_instance_type" {
  type = string
}

variable "enable_efs_integration" {
  type        = bool
  description = "Whether to deploy an EFS volume to provide support for ReadWriteMany volumes"
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

