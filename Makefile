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
	cd 1-ec2base; terraform apply -auto-approve 
	cd 2-k8sbase; terraform apply -auto-approve
	aws eks --region eu-west-1 update-kubeconfig --name mytests
	kubectl apply -f 2-k8sbase/namespace-dev.json;
	kubectl apply -f 2-k8sbase/rbac.yaml
	kubectl apply -f 2-k8sbase/configmap.yaml
	kubectl apply -f 2-k8sbase/deployment.yaml
deploy: apply
app-deploy:
	helm upgrade --install -f 3-jenkins/jenkins_params.yaml my-jenkins stable/jenkins
app-destroy:
	helm delete my-jenkins
destroy-all: app-destroy destroy
