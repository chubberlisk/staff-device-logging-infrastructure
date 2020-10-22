resource "aws_ssm_parameter" "instance_private_key" {
  name        = "/staff-device/logging/syslog_client/private_key"
  type        = "SecureString"
  value       = tls_private_key.ec2.private_key_pem
  overwrite   = true
  description = "TMP: SSH key for syslog client"
  tags        = var.tags
}
