variable "ami" {
  type        = string
  description = "AMI ID cua EC2"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Loai EC2"
}

variable "instance_name" {
  type        = string
  default     = "custom-ec2-cuong"
  description = "tag Name cua Instance"
}

variable "subnet_id" {
  type        = string
  description = "ID Subnet se dat EC2"
}

variable "vpc_id" {
  type        = string
  description = "ID VPC de tao SG di kem"
}
