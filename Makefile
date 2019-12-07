app-init:
	cd app; terraform init
app-plan:
	cd app; terraform plan
app-apply: 
	cd app; terraform apply
init:
	cd 1-ec2base; terraform init

plan:
	cd 1-ec2base; terraform plan

apply: 
	cd 1-ec2base; terraform apply
	#cd 2-k8sbase; make install

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
	cd 1-ec2base; terraform destroy
