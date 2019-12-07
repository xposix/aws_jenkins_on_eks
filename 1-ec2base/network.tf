module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.21.0"

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

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}