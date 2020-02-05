variable "project_tags" {
  type        = map
  description = "A key/value map containing tags to add to all resources"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to create a Mount Point on."
}

variable "client_sg" {
  description = "Security Group of the client that will access the EFS resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of VPC to deploy on the top of"
  type        = string
}

variable "existing_efs_volume" {
  description = "Volume ID of an existing EFS, used for Disaster Recovery purposes"
  type        = string
  default     = ""
}

variable "enable_efs_integration" {
  type        = bool
  description = "Whether to deploy an EFS volume to provide support for ReadWriteMany volumes"
  default     = false
}
