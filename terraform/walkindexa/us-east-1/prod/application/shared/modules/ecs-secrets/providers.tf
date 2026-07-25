terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.81.0"
    }

    secret = {
      source = "schizofreny/secret"
      version = "1.1.3"
    }
  }
}