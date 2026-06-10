terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    region       = "ap-southeast-1"
    bucket       = "state-storagec-cuong"
    key          = "state/terraform.tfstate"
    use_lockfile = true #từ version 1.10.0 trở lên mới dùng tính năng này được
    encrypt      = true
  }
}
provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "cuong_instance" {
  ami           = "ami-0f79166d4c42e6c1e"
  instance_type = var.instance_type

  tags = {
    Name = "cuong-ec2"
  }
}
