data "aws_region" "current" {}

locals {
  efs_volume_id     = var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id
  create_efs_volume = (var.existing_efs_volume == "") && var.enable_efs_integration ? 1 : 0
  subnets_to_create = var.enable_efs_integration ? var.subnet_ids : []
}

resource "aws_efs_file_system" "pdl" {
  count            = local.create_efs_volume
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = merge(map(
    "Name", "${var.project_tags["project_name"]}-EFS"),
  var.project_tags)
}

resource "aws_efs_mount_target" "efs_mts" {
  for_each       = toset(local.subnets_to_create)
  file_system_id = local.efs_volume_id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.EFSEndpoints[0].id
  ]
}

resource "aws_security_group" "EFSEndpoints" {
  count       = var.enable_efs_integration ? 1 : 0
  name        = "SGEFS-${var.project_tags["project_name"]}"
  description = "Allow EFS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    security_groups = [
      var.client_sg
    ]
  }
}

resource "aws_security_group_rule" "OutboundEFS" {
  count                    = var.enable_efs_integration ? 1 : 0
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.EFSEndpoints[0].id
  security_group_id        = var.client_sg
}

