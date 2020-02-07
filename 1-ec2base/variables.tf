variable "project_name" {
  type = string
}

variable "enable_bastion" {
  type    = bool
  default = true
}

variable "bastion_pem_key" {
  type = string
}
