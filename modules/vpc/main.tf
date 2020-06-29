module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.28.0"

  name = var.prefix

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  cidr                 = var.cidr_block

  azs = [
    "${var.region}a",
    "${var.region}b",
    "${var.region}c"
  ]

  private_subnets = [
    cidrsubnet(var.cidr_block, 8, 1),
    cidrsubnet(var.cidr_block, 8, 2),
    cidrsubnet(var.cidr_block, 8, 3)
  ]

  map_public_ip_on_launch = false
}
