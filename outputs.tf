output "lambda_shell_arn" {
  description = "The ARN of the Lambda function. Used for lambda-shell-resource and lambda-shell-data modules >= v0.2.0."
  value = module.shell_lambda.lambda.arn
}

output "invicton_labs_lambda_shell_arn" {
  description = "The ARN of the Lambda function. Used for lambda-shell-resource and lambda-shell-data modules < v0.2.0 (backwards compatibility)."
  value = module.shell_lambda.lambda.arn
}
