# Infrastructure requirements
EKS has very little infrastructure requirements, the general rules are here:
https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html

The most important in our case is that EKS depends on the VPC subnets being labeled correctly to be able to utilise them.
The tags those subnets have to use are detailed below. ${cluster_name} needs to be specified for each cluster being executed on those subnets.

## Private Subnets Labels
| Name  | Value |
| ----  | ----- |
| kubernetes.io/role/internal-elb | 1 |
| kubernetes.io/cluster/${cluster_name}| shared |
    

## Public Subnets Labels
| Name  | Value |
| ----  | ----- |
| kubernetes.io/role/elb | 1 |
| kubernetes.io/cluster/${cluster_name}| shared |
