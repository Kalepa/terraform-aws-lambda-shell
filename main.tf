resource "random_id" "lambda" {
  byte_length = 14
}

locals {

  // If no role/policy info is given, try using the current caller's role
  lambda_role = var.lambda_role_arn == null && var.lambda_role_policies_json == null && var.lambda_role_policy_arns == null ? local.caller_role_arn : var.lambda_role_arn
}

// Create the Lambda that will execute the shell commands
module "shell_lambda" {
  depends_on = [
    module.assert_role_present.checked,
    module.assert_single_role.checked
  ]
  source                   = "Invicton-Labs/lambda-set/aws"
  version                  = "~> 0.4.2"
  edge                     = false
  source_directory         = "${path.module}/lambda"
  archive_output_directory = "${path.module}/archives/"
  lambda_config = {
    function_name = "invicton-labs-aws-lambda-shell-${random_id.lambda.hex}"
    description   = var.lambda_description
    handler       = "main.lambda_handler"
    runtime       = var.lambda_runtime
    timeout       = var.lambda_timeout
    memory_size   = var.lambda_memory_size
    role          = local.lambda_role
    layers        = var.lambda_layer_arns
    // There seems to be a bug where, if you specify the x86_64 (default) architecture in a region that doesn't
    // support the arm64 architecture, it won't keep the architecture in the state file. This results in a
    // perpetual difference. So, if it's the default, we just set it to null and let it be default.
    architectures = var.lambda_architecture != "x86_64" ? [var.lambda_architecture] : null
    tags = {
      "ModuleAuthor" = "InvictonLabs"
      "ModuleUrl"    = "https://registry.terraform.io/modules/Invicton-Labs/lambda-shell/aws"
    }
    vpc_config = var.lambda_vpc_config
  }
  role_policies                 = var.lambda_role_policies_json == null ? [] : var.lambda_role_policies_json
  role_policy_arns              = var.lambda_role_policy_arns == null ? [] : var.lambda_role_policy_arns
  logs_lambda_subscriptions     = var.lambda_logs_lambda_subscriptions
  logs_non_lambda_subscriptions = var.lambda_logs_non_lambda_subscriptions
}
