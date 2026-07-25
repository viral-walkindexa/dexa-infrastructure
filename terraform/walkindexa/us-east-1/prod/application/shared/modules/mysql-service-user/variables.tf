variable "create_database" {
  type = bool
}

variable "database_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "mysql_endpoint" {
  type = string
}

variable "mysql_root_credentials_secret_arn" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "user" {
  type = object({
    username = string
    host = optional(string, "%")
  })
}