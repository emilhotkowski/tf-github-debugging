output "github-debugging-api_invoke_url" {
  description = "github-debugging-api invoke url"
  value       = aws_api_gateway_deployment.github-debugging-lambda-api-deployment.invoke_url
}
