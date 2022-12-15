# Account setup
variable "profile" {
  description           = "The profile from ~/.aws/credentials file used for authentication. By default it is the default profile."
  type                  = string
  default               = "default"
}

variable "accountID" {
  description           = "ID of your AWS account. It is a required variable normally used in JSON files or while assuming a role."
  type                  = string

  validation {
    condition           = length(var.accountID) == 12
    error_message       = "Please, provide a valid account ID."
  }
}

variable "region" {
  description           = "The region for the resources. By default it is eu-west-1."
  type                  = string
  default               = "eu-west-1"
}

variable "assumeRole" {
  description           = "Enable / Disable role assume. This is disabled by default and normally used for sub organization configuration."
  type                  = bool
  default               = false
}

variable "assumableRole" {
  description           = "The role the user will assume if assumeRole is enabled. By default, it is OrganizationAccountAccessRole."
  type                  = string
  default               = "OrganizationAccountAccessRole"
}

variable "name" {
  description = "Bucket name. Required value"
  type        = string
}
variable "object_lock_enabled" {
  description = "Create bucket with enabled or disabled object locks. You cannot change this value after the bucket is created. Be aware that object locks are not applied by default. Defaults to False."
  type        = bool
  default     = false
}
variable "object_lock_config" {
  description = "If you want to apply object lock to all newly created objects, please set the object lock configuration. E.g.: object_lock_config = { mode = \"COMPLIANCE\", days = 365 }. If this is set, all new object wont be possible to delete for 365 days."
  type        = map
  default     = {}
}
variable "block_public_acls" {
  description = "PUT Bucket ACL, PUT Object ACL and PUT Object if request includes a public ACL calls will fail if the specified ACL allows public access. Defaults to true"
  type        = bool
  default     = true
}
variable "block_public_policy" {
  description = "Reject calls to PUT Bucket policy if the specified bucket policy allows public access. Defaults to true"
  type        = bool
  default     = true
}
variable "ignore_public_acls" {
  description = "Ignore all public ACLs on buckets in this account and any objects that they contain. Defaults to true"
  type        = bool
  default     = true
}
variable "restrict_public_buckets" {
  description = "Only the bucket owner and AWS Services can access buckets with public policies. Defaults to true"
  type        = bool
  default     = true
}
variable "policy_path" {
  description = "Path to directory with all the policies. By default ./json/s3/NAME.json where the name is the name of the bucket"
  type        = string
  default     = "./json/s3"
}
variable "versioning_enabled" {
  description = "Enable or disable versioning on this bucket. Disabled versioning will not delete existing version, just suspend the service."
  type        = bool
  default     = true
}
variable "logging_bucket" {
  description = "Bucket name that is used for logging. If left blank string, logging will not be enabled."
  type        = string
  default     = ""
}
variable "logging_prefix" {
  description = "If logging is enabled, this is the first object in the object structure. By default if logging is enabled the path for the logs will be s3://logging_bucket/logging_prefix/bucket_name. Default value is s3."
  type        = string
  default     = "s3"
}
variable "lifecycle_rules" {
  description = "Lifecycle rules. By default empty. Example of one: lifecycle_rules = [{name = \"DeleteAnyInWeek\", enabled = true, expiration_date = \"\", expiration_days = 7}]"
  type        = any
  default     = []
}
variable "website_enabled" {
  description = "This will allow you to enable / disable website functionality on this bucket."
  type        = string
  default     = false
}
variable "website_index_page" {
  description = "Path to index page. Defaults to index.html"
  type        = string
  default     = "index.html"
}
variable "website_error_page" {
  description = "Path to error page. Defaults to 404.html"
  type        = string
  default     = "404.html"
}
variable "encryption_enabled" {
  description = "Enable disable S3 bucket encryption."
  type        = bool
  default     = true
}
variable "encryption_algorithm" {
  description = "Algorithm used for encryption. Default value is AES256. The other option is to use aws:kms. With kms you can use your own key provided below. If you leave the key empty, aws/s3 key will be used instead."
  type        = string
  default     = "AES256"
}
variable "encryption_kms_key" {
  description = "If aws:kms algoright is selected, you can use your own key to encrypt files. If this value is left blank and AES256 algorithm is not configured, aws will use own s3 kms key instead."
  type        = string
  default     = null
}
variable "cors_rules" {
  description = "CORS configuration. If left blank, no rules will be applied. Expected configuration. cors_rules = { allowed_methods = [\"GET\"], allowed_origins = [\"*\"] }. This is minimal required configuration if cors_rules are set. You can also configure allowed_headers and expose_headers."
  type        = any
  default     = {}
}