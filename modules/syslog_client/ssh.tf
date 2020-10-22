resource "tls_private_key" "ec2" {
  algorithm = "RSA"
}

resource "aws_key_pair" "syslog_client_keypair" {
  key_name   = "logging-syslog-client"
  public_key = tls_private_key.ec2.public_key_openssh
  tags       = var.tags
}
