# mod-terraform-aws-s3-bucket

Terraform module to create S3 bucket

## Variables

- **profile** - The profile from ~/.aws/credentials file used for authentication. By default it is the default profile.
- **accountID** - ID of your AWS account. It is a required variable normally used in JSON files or while assuming a role.
- **region** - The region for the resources. By default it is eu-west-1.
- **assumeRole** - Enable / Disable role assume. This is disabled by default and normally used for sub organization configuration.
- **assumableRole** - The role the user will assume if assumeRole is enabled. By default, it is OrganizationAccountAccessRole.
- **name** - Bucket name. Required value
- **object_lock_enabled** - Create bucket with enabled or disabled object locks. You cannot change this value after the bucket is created. Be aware that object locks are not applied by default. Defaults to False.
- **object_lock_config** - If you want to apply object lock to all newly created objects, please set the object lock configuration. E.g.: object_lock_config = { mode = "COMPLIANCE", days = 365 }. If this is set, all new object wont be possible to delete for 365 days.
- **block_public_acls** - PUT Bucket ACL, PUT Object ACL and PUT Object if request includes a public ACL calls will fail if the specified ACL allows public access. Defaults to true
- **block_public_policy** - Reject calls to PUT Bucket policy if the specified bucket policy allows public access. Defaults to true
- **ignore_public_acls** - Ignore all public ACLs on buckets in this account and any objects that they contain. Defaults to true
- **restrict_public_buckets** - Only the bucket owner and AWS Services can access buckets with public policies. Defaults to true
- **policy_path** - Path to directory with all the policies. By default ./json/s3/NAME.json where the name is the name of the bucket
- **versioning_enabled** - Enable or disable versioning on this bucket. Disabled versioning will not delete existing version, just suspend the service.
- **logging_bucket** - Bucket name that is used for logging. If left blank string, logging will not be enabled.
- **logging_prefix** - If logging is enabled, this is the first object in the object structure. By default if logging is enabled the path for the logs will be s3://logging_bucket/logging_prefix/bucket_name. Default value is s3.
- **lifecycle_rules** - Lifecycle rules. By default empty. Example of one: lifecycle_rules = [{name = "DeleteAnyInWeek", enabled = true, expiration_date = ", expiration_days = 7}]
- **website_enabled** - This will allow you to enable / disable website functionality on this bucket.
- **website_index_page** - Path to index page. Defaults to index.html
- **website_error_page** - Path to error page. Defaults to 404.html
- **encryption_enabled** - Enable disable S3 bucket encryption.
- **encryption_algorithm** - Algorithm used for encryption. Default value is AES256. The other option is to use aws:kms. With kms you can use your own key provided below. If you leave the key empty, aws/s3 key will be used instead.
- **encryption_kms_key** - If aws:kms algoright is selected, you can use your own key to encrypt files. If this value is left blank and AES256 algorithm is not configured, aws will use own s3 kms key instead.
- **cors_rules** - CORS configuration. If left blank, no rules will be applied. Expected configuration. cors_rules = { allowed_methods = ["GET"], allowed_origins = ["*"] }. This is minimal required configuration if cors_rules are set. You can also configure allowed_headers and expose_headers.
- **notification_sqs** - SQS configuration. Expected configuration: notification_sqs = { queue_arn = model.s3_sqs.arn, events = ["s3:ObjectCreated:*"], filter_suffix = "}. If left blank, sqs will not be notified
- **notification_lambda** - Lambda configuration. Expected configuration: notification_lambda = { lambda_function_arn = model.s3_lambda.arn, events = ["s3:ObjectCreated:*"], filter_suffix = "}. If left blank, lambda will not be notified

## Example

Each bucket requires bucket policy to be defined as JSON file in ./s3/name.json location. You can change the location with policy_path = ./policies

### Simple bucket

```terraform
variable accountID { default = "123456789012"}

module "s3_bucket_example" {
  source   = "git::https://github.com/virsas/mod-terraform-aws-s3-bucket.git?ref=v1.0.0"

  profile = "default"
  accountID = var.accountID
  region = "eu-west-1"

  name   = "example"
}
```

### Website bucket

```terraform
variable accountID { default = "123456789012"}

module "s3_bucket_example" {
  source   = "git::https://github.com/virsas/mod-terraform-aws-s3-bucket.git?ref=v1.0.0"

  profile = "default"
  accountID = var.accountID
  region = "eu-west-1"

  name   = "example"
  logging_bucket = module.s3-logs.id
  logging_prefix = "s3/log"
  policy_path    = "../policies"

  versioning_enabled = false
  website_enabled    = true
  website_index_page = "index.html"
  website_error_page = "index.html"
}

output "exampleEndpoint" {
  value = module.s3_bucket_example.website_endpoint
}
output "exampleRegionalDomain" {
  value = module.s3_bucket_example.bucket_regional_domain_name
}
```

### Bucket with lifecycle

```terraform
variable accountID { default = "123456789012"}

module "s3_bucket_example" {
  source   = "git::https://github.com/virsas/mod-terraform-aws-s3-bucket.git?ref=v1.0.3"

  profile = "default"
  accountID = var.accountID
  region = "eu-west-1"

  name   = "example"
  logging_bucket = module.s3-logs.id

  versioning_enabled = false

  lifecycle_rules = [
    {
      name = "All"
      expiration = {
        days = 180
      }
    }
  ]
}
```

### Bucket with CORS

```terraform
variable accountID { default = "123456789012"}

module "s3_bucket_example" {
  source   = "git::https://github.com/virsas/mod-terraform-aws-s3-bucket.git?ref=v1.0.3"

  profile = "default"
  accountID = var.accountID
  region = "eu-west-1"

  name   = "example"
  logging_bucket = module.s3-logs.id

  cors_rules = {
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
  }
}
```

### Bucket in sub organization

```terraform
module "s3_bucket_example" {
  source   = "git::https://github.com/virsas/mod-terraform-aws-s3-bucket.git?ref=v1.0.3"

  profile = "default"
  accountID = var.accountID
  region = "eu-west-1"

  assumeRole    = true
  assumableRole = "AdminRole"

  name          = "example"
}
```

## Outputs

- id
- arn
- bucket_domain_name
- bucket_regional_domain_name
- region
- s3_bucket_website_domain
- s3_bucket_website_endpoint
