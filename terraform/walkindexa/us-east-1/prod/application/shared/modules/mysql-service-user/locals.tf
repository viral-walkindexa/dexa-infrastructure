# Define the name of the specific database this user will have access to
locals {
  mysql_root_user_credentials = jsondecode(data.aws_secretsmanager_secret_version.core_rds_database_root_credentials.secret_string)
}

data "aws_secretsmanager_secret" "core_rds_database_root_credentials" {
  arn = var.mysql_root_credentials_secret_arn
}

data "aws_secretsmanager_secret_version" "core_rds_database_root_credentials" {
  secret_id = data.aws_secretsmanager_secret.core_rds_database_root_credentials.id
}