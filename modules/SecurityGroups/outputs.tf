output "database_securitygroup_id" {
  value = aws_security_group.dbsg.id
}

output "web_securitygroup_id" {
  value = aws_security_group.websg.id
}

output "app_securitygroup_id" {
  value = aws_security_group.appsg.id
}