resource "random_id" "lambda" {
  byte_length = 14
}

locals {
  // If no role/policy info is given, try using the current caller's role
  lambda_role = var.lambda_role_arn == null && length(var.lambda_role_policies_json) == 0 && length(var.lambda_role_policy_arns) == 0 ? local.caller_role_arn : var.lambda_role_arn
}

// Create the Lambda that will execute the shell commands
module "shell_lambda" {
  depends_on = [
    module.assert_role_present.checked,
    module.assert_single_body.checked
  ]
  source                   = "Invicton-Labs/lambda-set/aws"
  version                  = "~> 0.4.2"
  edge                     = false
  source_directory         = "${path.module}/lambda"
  archive_output_directory = "${path.module}/archives/"
  lambda_config = {
    function_name = "invicton-labs-aws-lambda-shell-${random_id.lambda.hex}"
    handler       = "main.lambda_handler"
    runtime       = "python3.9"
    timeout       = var.lambda_timeout
    memory_size   = var.lambda_memory_size
    role          = local.lambda_role
    layers        = var.lambda_layer_arns
    tags = {
      "ModuleAuthor" = "InvictonLabs"
      "ModuleUrl"    = "https://registry.terraform.io/modules/Invicton-Labs/lambda-shell/aws"
    }
    vpc_config = var.lambda_vpc_config
  }
  role_policies                 = var.lambda_role_policies_json
  role_policy_arns              = var.lambda_role_policy_arns
  logs_lambda_subscriptions     = var.lambda_logs_lambda_subscriptions
  logs_non_lambda_subscriptions = var.lambda_logs_non_lambda_subscriptions
}
