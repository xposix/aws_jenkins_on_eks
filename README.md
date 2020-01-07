# AWS EKS-based Services VPC
This project aims to create a blueprint of a complete Services VPC, fully containerised and based on AWS EKS, Terraform and Helm

# Requirements
The automated deployment process through Makefile requires Mac OS X.
You need to have fulfill the following requirements:

* AWS CLI tools installed (the `aws` command)
* AWS credentials (Access and Secret key of your IAM user) set up in your profile (the command `aws configure` will help)
* "GNU GCC make" installed (it should come by default with Mac OS and Linux)


# How to deploy automatically (Mac OS X)
I got a little bit too excited with the Makefile approach and I created sections to perform every action needed for the deployment. You need to execute the highlighted commands on the root directory of the repository.

1. `make mac-install`: (optional) installs all dependencies in your Mac:
    -   Terraform
    -   Helm
    -   aws-iam-authenticator
2. `make init`: uses Terraform to initialise your local copy of the deployment
3. `make plan`: (optional) uses Terraform to calculate changes to be done on an already-deployed environment once the terraform code has been updated. It's not necessary during the first deployment.
4. `make apply`: uses Terraform to deploy or update:
    -   A VPC with some generic IP addresses.
    -   Private and public subnets along with their respective NAT Gateways for Internet Access.
    -   An optional bastion host to enable external access to that VPC (not needed for accessing the tools)
    -   An AWS EKS cluster with a small instance (edit the `./2-k8sbase/cluster.tf` to make changes on instance type and number of instances)
    -   An EFS volume to store the Persistent Data Layer of used by the applications.
    -   K8s EFS provider to the Kubernetes pods can create volumes on the EFS volume.
    -   A k8s namespace that is not being used (everything is deployed on the default one... oooops, sorry!)
5. `make app-deploy`: uses Helm to deploy a Jenkins master on the EKS cluster using the EFS volume as storage backend.


# How to destroy
This process will remove the whole deployment, it's very handy on testing scenarios with small budget.

    make destroy-all

should destroy everything, but it's best to keep an eye on Terraform's logs in case something cannot be deleted and it's being left behind.
