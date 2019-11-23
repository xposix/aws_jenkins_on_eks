provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
  profile = "cr-labs-master"
  assume_role {
    role_arn     = "arn:aws:iam::787171992146:role/Admin"
    session_name = "SESSION_NAME"
  }
}