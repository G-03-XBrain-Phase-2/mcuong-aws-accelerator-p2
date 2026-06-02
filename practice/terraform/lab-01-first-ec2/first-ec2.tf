terraform {
  backend "s3" {
    bucket         = "mcuong-terraform-state"
    key            = "w8/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "StateLocking"
    encrypt        = true
  }
}
#variables
variable "access_key" {
  type        = string
  sensitive   = true
  description = "access key IAM User"
}

variable "secret_key" {
  type        = string
  sensitive   = true
  description = "secret key IAM User"
}
provider "aws" {
  region     = "ap-southeast-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_instance" "myec2" {
  ami           = "ami-0543dbdaf4e114be7"
  instance_type = "t3.micro"
  tags = {
    Name = "cuong-ec3"
  }
}
