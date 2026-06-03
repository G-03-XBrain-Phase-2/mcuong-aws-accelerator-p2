output "singapore_instance_ip" {
  value       = module.ec2_singapore.public_ip
  description = "The public IP of the EC2 instance in Singapore"
}

output "singapore_instance_az" {
  value       = module.ec2_singapore.availability_zone
  description = "The availability zone of the instance in Singapore"
}

output "us_east_instance_ip" {
  value       = module.ec2_us_east.public_ip
  description = "The public IP of the EC2 instance in US East"
}

output "us_east_instance_az" {
  value       = module.ec2_us_east.availability_zone
  description = "The availability zone of the instance in US East"
}
