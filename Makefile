app-init:
	cd app; terraform init
app-plan:
	cd app; terraform plan
app-apply: 
	cd app; terraform apply
init:
	cd tf; terraform init

plan:
	cd tf; terraform plan

apply: 
	cd tf; terraform apply
	cd k8sbase; make install

deploy: apply

app-deploy:
	helm install -f helm/jenkins_params.yaml my-jenkins stable/jenkins

app-destroy:
	helm uninstall my-jenkins

authenticate:
	aws eks --region eu-west-1 update-kubeconfig --name mytests

mac-install:
	brew upgrade aws-iam-authenticator helm terraform

destroy:
	cd tf; terraform destroy
