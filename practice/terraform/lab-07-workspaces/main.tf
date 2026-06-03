provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}

locals {
  # Cấu hình dynamic instance type dựa trên workspace
  instance_type = terraform.workspace == "prod" ? "t3.medium" : "t3.micro"

  # Cấu hình dynamic name tag
  instance_name = "cuong-server-${terraform.workspace}"
}

resource "aws_instance" "my_server" {
  ami           = var.ami
  instance_type = local.instance_type
  subnet_id     = var.subnet_id

  tags = {
    Name        = local.instance_name
    Environment = terraform.workspace
  }
}
