all: init apply app-deploy

authenticate:
	aws eks --region eu-west-1 update-kubeconfig --name mytests
mac-install:
	brew upgrade aws-iam-authenticator helm terraform
destroy:
	cd 2-k8sbase; terraform destroy -auto-approve
	cd 1-ec2base; terraform destroy -auto-approve

init:
	cd 1-ec2base; terraform init
	cd 2-k8sbase; terraform init
plan:
	cd 1-ec2base; terraform plan
	cd 2-k8sbase; terraform plan

apply: 
	cd 1-ec2base; terraform apply -auto-approve;
	cd 2-k8sbase; kubectl apply -f namespace-dev.json; terraform apply -auto-approve
deploy: apply

app-init:
	cd app; terraform init
app-plan:
	cd app; terraform plan
app-apply: 
	cd app; terraform apply -auto-approve
app-deploy:
	helm install -f helm/jenkins_params.yaml my-jenkins stable/jenkins
app-destroy:
	helm uninstall my-jenkins
destroy-all: app-destroy destroy
