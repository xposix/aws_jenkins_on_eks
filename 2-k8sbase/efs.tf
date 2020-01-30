data "aws_region" "current" {}

resource "aws_efs_file_system" "pdl" {
  creation_token   = "Test-pdl"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "${var.project_name}_PDL"
  }
}

resource "aws_efs_mount_target" "az1" {
  file_system_id = aws_efs_file_system.pdl.id
  subnet_id      = element("${data.terraform_remote_state.networking.outputs.private_subnets}",0)
  security_groups = [
    aws_security_group.EFS.id
  ]
}

resource "aws_efs_mount_target" "az2" {
  file_system_id = aws_efs_file_system.pdl.id
  subnet_id      = element("${data.terraform_remote_state.networking.outputs.private_subnets}",1)
  security_groups = [
    aws_security_group.EFS.id
  ]
}

resource "aws_security_group" "EFS" {
  name        = "SGEFS-${var.project_name}"
  description = "Allow EFS inbound traffic"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    # security_groups = [
    #   module.eks-cluster.worker_security_group_id
    # ]
  }
}

resource "aws_security_group_rule" "OutboundEFS" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.EFS.id
  security_group_id        = aws_security_group.EFS_client.id
}

resource "local_file" "configmap-efs" {
  content  = templatefile("${path.module}/configmap-efs.yaml.tmpl", { fsid = aws_efs_file_system.pdl.id, region = data.aws_region.current.name })
  filename = "${path.module}/configmap-efs.yaml"
}

resource "local_file" "deployment-efs" {
  content  = templatefile("${path.module}/deployment-efs.yaml.tmpl", { fsid = aws_efs_file_system.pdl.id, region = data.aws_region.current.name })
  filename = "${path.module}/deployment-efs.yaml"
}
