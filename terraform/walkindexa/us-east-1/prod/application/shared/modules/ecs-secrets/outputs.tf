output "secret_arns" {
  value = { for secret_name, secret_resource in aws_secretsmanager_secret.secret :
    secret_name => secret_resource.arn
  }
}