terraform {
  backend "s3" {
    region         = "ap-southeast-1"
    bucket         = "mcuong-terraform-state"
    key            = "module/terraform.tfstate"
    dynamodb_table = "StateLocking"
    encrypt        = true
  }
}
provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

module "cuong_web_server" {
  source        = "./modules/custom-ec2"
  ami           = var.ami
  instance_type = var.instance_type
  instance_name = var.instance_name
  subnet_id     = "subnet-0faeb15bf1e0dafa3"
  vpc_id        = "vpc-0674317770df05b63"
}

