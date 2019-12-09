data "terraform_remote_state" "networking" {
    backend = "local"

    config = {
        path = "${path.module}/../1-ec2base/terraform.tfstate"
    }

}