Terraform module which create both VPC and other resources on Alibaba Cloud.  
terraform-alicloud-demo
=============================================


## Terraform versions

The Module requires Terraform 0.12 and Terraform Provider AliCloud 1.56.0+.

## Usage

```hcl
module "test-environment" {
  source       = "xiaozhu36/demo/alicloud"
  region       = "cn-beijing"
  env          = "test"
  zone_for_ecs = "cn-beijing-e"
  zone_for_rds = "cn-beijing-d"
}
```