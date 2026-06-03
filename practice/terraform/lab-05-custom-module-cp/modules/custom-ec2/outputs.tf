output "instance_id" {
  value       = aws_instance.cuong-ec2.id
  description = "ID cua EC2 Instance"
}

output "public_ip" {
  value       = aws_instance.cuong-ec2.public_ip
  description = "Public IP cua EC2 Instance"
}
output "security_group_id" {
  value       = aws_security_group.cuong_sg.id
  description = "SG ID vua tao"
}
