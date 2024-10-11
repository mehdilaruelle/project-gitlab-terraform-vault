data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "amzlinux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Authorize HTTP interaction with web server"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "userdata" {
  template = file("${path.module}/userdata.sh")
  vars = {
    vault_addr             = var.vault_addr
    db_host                = aws_db_instance.web.endpoint
    db_name                = aws_db_instance.web.db_name
    vault_auth_path        = var.vault_app_auth_aws_path
    vault_version          = var.vault_agent_version
    vault_agent_parameters = var.vault_agent_parameters
    db_secret_path         = "${var.vault_app_secret_db_path}/creds/${var.project_name}"
    role_name              = var.project_name
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amzlinux.id
  instance_type          = var.aws_instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = data.template_file.userdata.rendered
  monitoring             = false
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db"
  description = "Allow mysql inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Authorize HTTP interaction with webserv"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "web" {
  allocated_storage      = var.aws_db_storage_size
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.aws_db_instance_class
  db_name                = var.project_name
  username               = var.db_admin_username
  password               = random_password.password.result
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  publicly_accessible    = var.aws_db_publicly_accessible
}
