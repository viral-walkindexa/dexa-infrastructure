terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.2.0"
    }
    mysql = {
      source = "petoju/mysql"
      version = "~> 3.0.78"
    }
  }
}

provider "mysql" {
  endpoint = var.mysql_endpoint
  username = local.mysql_root_user_credentials["username"]
  password = local.mysql_root_user_credentials["password"]
}