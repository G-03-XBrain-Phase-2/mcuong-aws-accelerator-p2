variable "ami" {
  type        = string
  description = "The AMI ID to use for the instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "The type of instance to start"
}

variable "instance_name" {
  type        = string
  default     = "multi-region-ec2"
  description = "The Name tag of the EC2 instance"
}

variable "subnet_id" {
  type        = string
  description = "The Subnet ID to launch in"
}
