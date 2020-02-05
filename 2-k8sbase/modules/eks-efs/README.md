# EFS module for AWS EKS
Terraform module for EFS integration with AWS EKS.

## Usage

```
module "eks-efs" {
  source = "./modules/eks-efs"
  project_tags = {
    project_name = "my_test"
  }
  subnet_ids = [
    "sn-123456",
    "sn-123457"
  ]
  client_sg = "sg-12345678"
  vpc_id    = "vpc-12345678"
  # Only for DR purposes:
  existing_efs_volume = "fs-12345678"
}
```


## Input Parameters
| Name        | Description     |
|:-------------:|-------------|
| project_tags | A key/value map containing tags to add to all resources. See the `tagging` section below. |
| vpc_id | ID of VPC to deploy on the top of. |
| subnet_ids | List of subnet IDs to create a Mount Point on. |
| client_sg | Security Group of the client that will access the EFS resources.  |
| existing_efs_volume | Volume ID of an existing EFS, used for Disaster Recovery purposes. |


### Tagging
All the tags are passed as a Terraform map, see an example below with suggested tag names:

```javascript
    project_tags = {
        "name"        = "new_project"
        "environment" = "test"
    }
```


## Output parameters

None