resource "secret_resource" "secret" {
  for_each = var.secrets
}
resource "aws_secretsmanager_secret" "secret" {
  for_each = var.secrets
  name = "${var.name_prefix}-${each.value}"
}

resource "aws_secretsmanager_secret_version" "secret" {
  for_each = var.secrets
  secret_id = aws_secretsmanager_secret.secret[each.key].id
  secret_string = secret_resource.secret[each.key].value
}