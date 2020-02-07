data "aws_region" "current" {}

locals {
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
  file_system_id = var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id
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

resource "aws_cloudwatch_metric_alarm" "efs_burstcreditbalance" {
  count               = var.sns_notification_topic_arn != "" ? 1 : 0
  alarm_name          = "efs_burstcreditbalance"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "10"
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = "120"
  statistic           = "Average"
  threshold           = 1.5 * pow(10, 12) # 1.5 TiB
  alarm_description   = "EFS credits usage"
  alarm_actions = [
    var.sns_notification_topic_arn
  ]
  dimensions = {
    FileSystemId = var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "efs_percentiolimit" {
  count               = var.sns_notification_topic_arn != "" ? 1 : 0
  alarm_name          = "efs_percentiolimit"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "4"
  metric_name         = "PercentIOLimit"
  namespace           = "AWS/EFS"
  period              = "120"
  statistic           = "Maximum"
  threshold           = 95
  alarm_description   = "EFS IO limit percentage"
  alarm_actions = [
    var.sns_notification_topic_arn
  ]
  dimensions = {
    FileSystemId = var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id
  }
}

resource "aws_cloudwatch_metric_alarm" "efs_permittedthroughput" {
  count               = var.sns_notification_topic_arn != "" ? 1 : 0
  alarm_name          = "efs_permittedthroughput"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "10"
  metric_name         = "PermittedThroughput"
  namespace           = "AWS/EFS"
  period              = "180"
  statistic           = "Minimum"
  threshold           = 80
  alarm_description   = "EFS IO limit in MB/s"
  alarm_actions = [
    var.sns_notification_topic_arn
  ]
  dimensions = {
    FileSystemId = var.existing_efs_volume != "" ? var.existing_efs_volume : aws_efs_file_system.pdl[0].id
  }
}
