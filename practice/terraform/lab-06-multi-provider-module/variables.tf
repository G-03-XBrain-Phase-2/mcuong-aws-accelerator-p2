variable "aws_region_sg" {
  type    = string
  default = "ap-southeast-1"
}

variable "aws_region_us" {
  type    = string
  default = "us-east-1"
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

variable "ami_sg" {
  type        = string
  default     = "ami-0543dbdaf4e114be7" # Amazon Linux 2023 in ap-southeast-1
  description = "AMI ID for Singapore region"
}

variable "ami_us" {
  type        = string
  default     = "ami-00c39f71452c08778" # Amazon Linux 2023 in us-east-1
  description = "AMI ID for US East (N. Virginia) region"
}

variable "subnet_id_sg" {
  type        = string
  description = "Subnet ID in ap-southeast-1"
}

variable "subnet_id_us" {
  type        = string
  description = "Subnet ID in us-east-1"
}
