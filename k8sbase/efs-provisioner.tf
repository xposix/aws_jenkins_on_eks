data "aws_region" "current" {}

resource "helm_release" "efs-provisioner" {
  name      = "efs-provisioner"
  chart     = "stable/efs-provisioner"
  namespace = "development"

  set {
    name  = "efsProvisioner.efsFileSystemId"
    value = aws_efs_file_system.pdl.id
  }

  set {
    name  = "efsProvisioner.awsRegion"
    value = data.aws_region.current.name
  }
}

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
}

resource "aws_efs_mount_target" "az2" {
  file_system_id = aws_efs_file_system.pdl.id
  subnet_id      = data.terraform_remote_state.networking.outputs.sn_az2
}