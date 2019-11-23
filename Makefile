
init:
	cd tf; terraform init

plan:
	cd tf; terraform plan

apply: 
	cd tf; terraform apply

authenticate:
	aws eks --region eu-west-1 update-kubeconfig --name mytests

mac_install:
	brew upgrade aws-iam-authenticator helm terraform
