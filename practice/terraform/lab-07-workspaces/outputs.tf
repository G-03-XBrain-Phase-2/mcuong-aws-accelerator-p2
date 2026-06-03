output "current_workspace" {
  value       = terraform.workspace
  description = "The name of the active Terraform workspace"
}

output "instance_ip" {
  value       = aws_instance.my_server.public_ip
  description = "The public IP address of the EC2 instance"
}

output "instance_name_tag" {
  value       = aws_instance.my_server.tags.Name
  description = "The Name tag of the EC2 instance"
}

output "instance_type" {
  value       = aws_instance.my_server.instance_type
  description = "The size/type of the deployed EC2 instance"
}
