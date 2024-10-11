provider "vault" {
  address = var.vault_addr
}

data "vault_aws_access_credentials" "creds" {
  backend = var.vault_secret_aws_backend
  role    = var.vault_secret_aws_role
  type    = "sts"
}

provider "aws" {
  region     = var.region
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  token      = data.vault_aws_access_credentials.creds.security_token

  default_tags {
    tags = {
      Name = var.project_name
    }
  }
}
