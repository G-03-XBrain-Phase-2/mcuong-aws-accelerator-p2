output "instance_id" {
  value       = aws_instance.this.id
  description = "The ID of the EC2 instance"
}

output "public_ip" {
  value       = aws_instance.this.public_ip
  description = "The public IP address of the EC2 instance"
}

output "availability_zone" {
  value       = aws_instance.this.availability_zone
  description = "The availability zone where instance is deployed"
}
