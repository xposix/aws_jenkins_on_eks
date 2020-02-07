output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "sg_bastion" {
  value = aws_security_group.SGBastion
}

output "bastion_host" {
  value = module.ec2_cluster.public_ip
}
