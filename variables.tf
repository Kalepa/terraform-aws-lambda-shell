variable "lambda_description" {
  description = "The description string to apply to the Lambda function."
  type        = string
  default     = "Kalepa/lambda-shell/aws (https://registry.terraform.io/modules/Kalepa/lambda-shell/aws)"
}

variable "lambda_timeout" {
  description = "The timeout (in seconds) for the Lambda function that is running the shell command."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "The memory size (in MB) for the Lambda function that is running the shell command."
  type        = number
  default     = 128
}

variable "lambda_role_arn" {
  description = "The ARN of the role to use for the Lambda that runs shell commands. If this value is provided, a new role will not be created. Conflicts with `lambda_role_policy_json`. If neither is provided, the module will attempt to use the role that the Terraform caller has assumed (if a role has been assumed)."
  type        = string
  default     = null
}

variable "lambda_architecture" {
  description = "The architecture to use for the Lambda function."
  type        = string
  default     = "x86_64"
  validation {
    condition     = contains(["x86_64", "arm64"], var.lambda_architecture)
    error_message = "The `lambda_architecture` variable must be `x86_64` or `arm64`."
  }
}

variable "lambda_role_policies_json" {
  description = "A list of JSON-encoded policies to apply to a new role that will be created for the Lambda that runs shell commands. Conflicts with `lambda_role_arn`. If neither is provided, the module will attempt to use the role that the Terraform caller has assumed (if a role has been assumed)."
  type        = list(string)
  default     = null
}

variable "lambda_role_policy_arns" {
  description = "A list of IAM policy ARNs to apply to a new role that will be created for the Lambda that runs shell commands. Conflicts with `lambda_role_arn`. If neither is provided, the module will attempt to use the role that the Terraform caller has assumed (if a role has been assumed)."
  type        = list(string)
  default     = null
}

variable "lambda_logs_lambda_subscriptions" {
  description = "A list of configurations for Lambda subscriptions to the CloudWatch Logs Group for the Lambda function that runs shell commands. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "lambda_logs_non_lambda_subscriptions" {
  description = "A list of configurations for non-Lambda subscriptions to the CloudWatch Logs Group for the Lambda function that runs shell commands. Each element should be a map with `destination_arn` (required), `name` (optional), `filter_pattern` (optional), `role_arn` (optional), and `distribution` (optional)."
  type = list(object({
    destination_arn = string
    name            = optional(string)
    filter_pattern  = optional(string)
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = []
}

variable "lambda_vpc_config" {
  description = "The VPC configuration for the Lambda."
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "lambda_layer_arns" {
  description = "A list of Lambda Layer ARNs to attach to the Lambda."
  type        = list(string)
  default     = []
}

variable "lambda_runtime" {
  description = "The runtime to use for the lambda shell."
  type        = string
  default     = "python3.9"
  validation {
    condition     = contains(["python3.7", "python3.8", "python3.9"], var.lambda_runtime)
    error_message = "The `lambda_runtime` variable must be `python3.7`, `python3.8`, or `python3.9`."
  }
}

data "aws_caller_identity" "current" {}

data "aws_arn" "role" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  caller_role_arn = substr(data.aws_arn.role.resource, 0, 5) == "role/" ? data.aws_caller_identity.current.arn : (substr(data.aws_arn.role.resource, 0, 13) == "assumed-role/" && substr(data.aws_arn.role.resource, 13, 15) != "AWSReservedSSO_" ? "arn:${data.aws_arn.role.partition}:iam::${data.aws_arn.role.account}:role/${split("/", data.aws_arn.role.resource)[1]}" : null)
}

module "assert_role_present" {
  source        = "Kalepa/assertion/null"
  version       = "~> 0.2"
  condition     = var.lambda_role_arn != null || var.lambda_role_policies_json != null || var.lambda_role_policy_arns != null || local.caller_role_arn != null
  error_message = "One of the `lambda_role_arn`, `lambda_role_policies_json`, or `lambda_role_policy_arns` input parameters must be provided, or this module must be called from a Terraform configuration that has assumed a role."
}
module "assert_single_role" {
  source        = "Kalepa/assertion/null"
  version       = "~> 0.2"
  condition     = var.lambda_role_arn == null || (var.lambda_role_policies_json == null && var.lambda_role_policy_arns == null)
  error_message = "The `lambda_role_arn` cannot be provided when either the `lambda_role_policies_json` or `lambda_role_policy_arns` input parameter is provided."
}
