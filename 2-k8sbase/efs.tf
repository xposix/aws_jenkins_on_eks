data "aws_region" "current" {}

resource "aws_efs_file_system" "pdl" {
  creation_token   = "Test-pdl"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "PDL"
  }
}

resource "aws_efs_mount_target" "az1" {
  file_system_id = aws_efs_file_system.pdl.id
  subnet_id      = data.terraform_remote_state.networking.outputs.sn_az1
  security_groups = [
    aws_security_group.EFS.id
  ]
}

resource "aws_efs_mount_target" "az2" {
  file_system_id = aws_efs_file_system.pdl.id
  subnet_id      = data.terraform_remote_state.networking.outputs.sn_az2
  security_groups = [
    aws_security_group.EFS.id
  ]
}

resource "aws_security_group" "EFS" {
  name        = "SGEFS"
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

resource "local_file" "configmap" {
  content  = templatefile("${path.module}/configmap.yaml.tmpl", { fsid = aws_efs_file_system.pdl.id, region = data.aws_region.current.name })
  filename = "${path.module}/configmap.yaml"
}

resource "local_file" "deployment" {
  content  = templatefile("${path.module}/deployment.yaml.tmpl", { fsid = aws_efs_file_system.pdl.id, region = data.aws_region.current.name })
  filename = "${path.module}/deployment.yaml"
}
