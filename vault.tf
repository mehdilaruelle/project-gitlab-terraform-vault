// Put secret into Vault
resource "vault_database_secret_backend_connection" "mysql" {
  backend       = var.vault_app_secret_db_path
  name          = "mysql"
  allowed_roles = [var.project_name]

  mysql {
    connection_url = "${aws_db_instance.web.username}:${random_password.password.result}@tcp(${aws_db_instance.web.endpoint})/"
  }
}

// Create a role for readonly user in database
resource "vault_database_secret_backend_role" "role" {
  backend               = var.vault_app_secret_db_path
  name                  = var.project_name
  db_name               = vault_database_secret_backend_connection.mysql.name
  creation_statements   = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"]
  revocation_statements = ["DROP USER '{{name}}'@'%';"]
  default_ttl           = var.db_secret_ttl
}

// Rotate root credentials
/*
data "vault_generic_endpoint" "db_rotate" {
  path = "${local.db_backend}/rotate-root/${var.project_name}"
}
*/

// Allow the application to auth with AWS method
resource "vault_aws_auth_backend_role" "web" {
  backend           = var.vault_app_auth_aws_path
  role              = var.project_name
  auth_type         = "ec2"
  bound_ami_ids     = [data.aws_ami.amzlinux.id]
  bound_account_ids = [data.aws_caller_identity.current.account_id]
  bound_vpc_ids     = [data.aws_vpc.default.id]
  bound_subnet_ids  = [aws_instance.web.subnet_id]
  bound_regions     = [var.region]
  token_ttl         = var.project_token_ttl
  token_max_ttl     = var.project_token_max_ttl
  token_policies    = ["default", var.project_name]
}
