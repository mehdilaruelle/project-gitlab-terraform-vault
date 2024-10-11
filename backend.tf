terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~>4.4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.70"
    }
  }

  backend "remote" {}
}
