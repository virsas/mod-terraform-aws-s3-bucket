# mod-terraform-aws-lambda

Terraform module to create AWS lambda function with optional permissions.

## Variables

- **profile** - The profile from ~/.aws/credentials file used for authentication. By default it is the default profile.
- **accountID** - ID of your AWS account. It is a required variable normally used in JSON files or while assuming a role.
- **region** - The region for the resources. By default it is eu-west-1.
- **assumeRole** - Enable / Disable role assume. This is disabled by default and normally used for sub organization configuration.
- **assumableRole** - The role the user will assume if assumeRole is enabled. By default, it is OrganizationAccountAccessRole.

## Example

``` terraform
variable accountID { default = "123456789012"}

module "s3_bucket_example" {
  source   = "git::https://github.com/virsas/mod-terraform-aws-s3-bucket.git?ref=v1.0.0"

  profile = "default"
  accountID = var.accountID
  region = "us-east-1"
}

output "s3_bucket_example_arn" {
    value = module.s3_bucket_example.arn
}
```

## Outputs

- id
- arn
- bucket_domain_name
- bucket_regional_domain_name
- s3_bucket_hosted_zone_id
- region
- s3_bucket_website_domain