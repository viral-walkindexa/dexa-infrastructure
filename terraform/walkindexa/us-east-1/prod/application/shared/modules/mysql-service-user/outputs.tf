output "mysql_user_password_secret_arn" {
  value       = aws_secretsmanager_secret_version.user_password.arn
}

output "mysql_username" {
  value       = mysql_user.single_db_access_user.user
}

output "mysql_database_name" {
  value       = var.database_name
}