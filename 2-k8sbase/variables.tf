variable "project_name" {
  type = string
}

variable "bastion_pem_key" {
  type = string
}

variable "enable_efs_integration" {
  type        = bool
  description = "Whether to deploy an EFS volume to provide support for ReadWriteMany volumes"
}
