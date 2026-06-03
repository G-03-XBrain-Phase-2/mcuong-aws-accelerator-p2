variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "session_token" {
  type      = string
  sensitive = true
  default   = null
}

variable "ami" {
  type    = string
  default = "ami-0543dbdaf4e114be7" # Amazon Linux 2023 ở Singapore
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_name" {
  type    = string
  default = "cuong-lab05-web"
}
