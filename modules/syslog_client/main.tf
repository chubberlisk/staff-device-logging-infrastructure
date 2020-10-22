data "template_file" "syslog_client" {
  template = "${file("${path.module}/syslog_client.py")}"

  vars = {
    load_balancer_ip = var.load_balancer_ip
  }
}

data "aws_ami" "amazon_linux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20200617.0-x86_64-gp2"]
  }

  owners = ["137112412989"]
}

resource "aws_instance" "syslog_client" {
  count                  = var.instance_count
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = "t2.small"
  vpc_security_group_ids = list(aws_security_group.syslog_client.id)
  subnet_id              = var.subnet
  key_name               = aws_key_pair.syslog_client_keypair.key_name
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.syslog_client.name

  tags = {
    Name = "${var.prefix}-syslog-test-client"
  }

  user_data = <<EOF
#!/bin/bash -xe

yum -y update
yum install python3 awslogs -y

sudo systemctl start awslogsd
mkdir ~/syslog_client
echo '${data.template_file.syslog_client.rendered}' >> ~/syslog_client/syslog_client.py
cd ~/syslog_client

while true; do
  python -c "import syslog_client; s = syslog_client.Syslog(); s.send({"host": "Staff-Device-Syslog-Host", "ident": "1", "message": "Hello Syslog", "pri": "134"}, syslog_client.Level.WARNING);"
  sleep 1
  echo "hi"
done
EOF
}

resource "aws_security_group" "syslog_client" {
  name = "${var.prefix}-syslog-endpoint-load-test-security-group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = var.syslog_endpoint_vpc
}
