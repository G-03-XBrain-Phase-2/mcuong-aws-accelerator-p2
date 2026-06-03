output "cuong_web_server" {
  value       = module.cuong_web_server.public_ip
  description = "Public IP cua web server"
}

output "cuong_web_server_sg-id" {
  value       = module.cuong_web_server.security_group_id
  description = "Security Group gan voi EC2"
}
