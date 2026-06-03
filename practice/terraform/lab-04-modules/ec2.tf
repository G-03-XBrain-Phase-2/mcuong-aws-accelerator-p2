#variables
variable "access_key" {
  type      = string
  sensitive = true
}
variable "secret_key" {
  type      = string
  sensitive = true
}
provider "aws" {
  region     = "ap-southeast-1"
  access_key = var.access_key
  secret_key = var.secret_key
}
module "ec2-instance" {
  source    = "terraform-aws-modules/ec2-instance/aws"
  version   = "6.4.0"
  subnet_id = "subnet-09ce9bf2bcd643f09"
}
