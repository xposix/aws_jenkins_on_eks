module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc"

  name = "my-vpc"
  cidr = "10.10.10.0/23"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.10.10.0/25", "10.10.10.128/25"]
  public_subnets  = ["10.10.11.0/25", "10.10.11.128/25"]

  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags	= {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = {
    Terraform = "true"
    Environment = "dev"
    "kubernetes.io/cluster/mytests" = "shared"
  }
}