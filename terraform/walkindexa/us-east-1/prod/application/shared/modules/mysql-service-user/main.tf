resource "random_password" "db_user_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*"
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
  min_lower        = 1
}

resource "mysql_database" "target_database" {
  count                 = var.create_database ? 1 : 0
  name                  = var.database_name
  default_character_set = "utf8mb4"
  default_collation     = "utf8mb4_0900_ai_ci"

  lifecycle {
    prevent_destroy = true
  }
}

resource "mysql_user" "single_db_access_user" {
  user               = var.user.username
  host               = var.user.host
  plaintext_password = random_password.db_user_password.result
}

resource "mysql_grant" "single_db_access_grant" {
  user              = mysql_user.single_db_access_user.user
  host              = mysql_user.single_db_access_user.host
  database          = var.database_name
  table             = "*"
  privileges = ["ALL PRIVILEGES"]
  grant = false

  depends_on = [mysql_database.target_database]
}

resource "aws_secretsmanager_secret" "user_password" {
  name = "${var.name_prefix}-${var.database_name}-${var.user.username}-${var.environment}"
}

resource "aws_secretsmanager_secret_version" "user_password" {
  secret_id     = aws_secretsmanager_secret.user_password.id
  secret_string = random_password.db_user_password.result
}