all: init apply app-deploy

mac-install:
	brew upgrade kubectl aws-iam-authenticator helm terraform

init:
	cd 1-ec2base; terraform init
	cd 2-k8sbase; terraform init
plan:
	cd 1-ec2base; terraform plan
	cd 2-k8sbase; terraform plan
deploy: apply

ec2base-deploy:
	cd 1-ec2base; terraform apply -auto-approve

kubeconf_path_parameter = --kubeconfig ./kubeconfig

k8sbase-deploy:
	cd 2-k8sbase; terraform apply -auto-approve
	helm upgrade --install $(kubeconf_path_parameter) dashboard stable/kubernetes-dashboard --namespace k8sdashboard --set rbac.clusterAdminRole=true

apply: ec2base-deploy k8sbase-deploy
	# kubectl apply -f 2-k8sbase/namespace-dev.json $(kubeconf_path_parameter)
	# kubectl apply -f 2-k8sbase/rbac-efs.yaml $(kubeconf_path_parameter)
	# kubectl apply -f 2-k8sbase/configmap-efs.yaml $(kubeconf_path_parameter)
	# kubectl apply -f 2-k8sbase/deployment-efs.yaml $(kubeconf_path_parameter)

app-deploy:
	helm upgrade --install $(kubeconf_path_parameter) -f 3-jenkins/jenkins_params.yaml jenkins stable/jenkins

destroy: app-destroy infra-destroy

app-destroy:
	helm delete jenkins

infra-destroy:
	helm delete dashboard
	cd 2-k8sbase; terraform destroy -auto-approve
	cd 1-ec2base; terraform destroy -auto-approve

