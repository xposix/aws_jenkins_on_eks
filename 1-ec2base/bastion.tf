module "ec2_cluster" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"
  name                   = "bastion"
  instance_count         = 1
  ami                    = "ami-01f14919ba412de34"
  instance_type          = "t3a.nano"
  key_name               = ""
  monitoring             = false
  vpc_security_group_ids = [ aws_security_group.SGBastion.id ]
  subnet_id              = element("${module.vpc.public_subnets}",0)

  tags = {
    Environment = "dev"
  }
}

resource "aws_security_group" "SGBastion" {
  name        = "SGBastion"
  description = "Allow access through bastion"
  vpc_id      = module.vpc.vpc_id

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "77.97.149.36/32" ]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}