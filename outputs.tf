output "invicton_labs_lambda_shell_arn" {
  description = "The ARN of the Lambda function. The output is oddly named because it's used to ensure that the correct module is passed into the lambda-shell-resource and lambda-shell-data modules."
  value = module.shell_lambda.lambda.arn
}
