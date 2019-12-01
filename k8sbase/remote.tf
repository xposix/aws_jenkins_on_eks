data "terraform_remote_state" "networking" {
    backend = "local"

    config = {
        path = "${path.module}/../tf/terraform.tfstate"
    }

}