module "vpc" {
  source = "./modules/terraform-aws-vpc"

  name = "my-vpc"
  cidr = "10.10.10.0/23"

  azs             = ["eu-west-1a", "eu-west-1b"]
  private_subnets = ["10.10.10.0/25", "10.10.10.128/25"]
  public_subnets  = ["10.10.11.0/25", "10.10.11.128/25"]

  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}