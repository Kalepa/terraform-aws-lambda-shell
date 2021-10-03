output "invicton_labs_lambda_shell_arn" {
  description = "The ARN of the Lambda function. The output is oddly named because it's used to ensure that the correct module is passed into the lambda-shell-resource and lambda-shell-data modules."
  // Use the "complete" output of the inner Lambda module so that the function ARN can't be used until everything has been completed (permissions have been applied)
  value = module.shell_lambda.complete ? module.shell_lambda.lambda.arn : module.shell_lambda.lambda.arn
}
