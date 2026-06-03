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
  type        = string
  default     = "ami-0543dbdaf4e114be7" # Amazon Linux 2023 in ap-southeast-1
  description = "AMI ID of the EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where instance will reside"
}
