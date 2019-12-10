output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "private_subnets" {
  value = "${module.vpc.private_subnets}"
}

output "sn_az1" {
  value = element("${module.vpc.private_subnets}",0)
}

output "sn_az2" {
  value = element("${module.vpc.private_subnets}",1)
}

output "sg_bastion" {
  value = aws_security_group.SGBastion
}

output "bastion_host" {
  value = module.ec2_cluster.public_ip
}