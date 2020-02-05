
module "eks-efs" {
  source = "https://github.com/clear-ai/tfm_efs_for_eks.git"
  project_tags = {
    project_name = "test"
  }
  subnet_ids = [
    element("${data.terraform_remote_state.networking.outputs.private_subnets}", 0),
    element("${data.terraform_remote_state.networking.outputs.private_subnets}", 1)
  ]
  client_sg              = "sg-0194f49f77a9d3ed2"
  vpc_id                 = data.terraform_remote_state.networking.outputs.vpc_id
  enable_efs_integration = var.enable_efs_integration
}
