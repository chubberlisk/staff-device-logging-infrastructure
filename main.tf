terraform {
  required_version = "> 0.12.0"

  backend "s3" {
    bucket         = "pttp-ci-infrastructure-client-core-tf-state"
    dynamodb_table = "pttp-ci-infrastructure-client-core-tf-lock-table"
    region         = "eu-west-2"
  }
}

provider "aws" {
  version = "~> 2.68"
  alias   = "env"
  assume_role {
    role_arn = var.assume_role
  }
}

provider "tls" {
  version = "> 2.1"
}

data "aws_region" "current_region" {}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.16.0"

  namespace = "pttp"
  stage     = terraform.workspace
  name      = "infra"
  delimiter = "-"

  tags = {
    "business-unit" = "MoJO"
    "application"   = "infrastructure",
    "is-production" = tostring(var.is-production),
    "owner"         = var.owner_email

    "environment-name" = "global"
    "source-code"      = "https://github.com/ministryofjustice/pttp-infrastructure"
  }
}

# module "bootstrap" {
#   source                      = "./modules/bootstrap"
#   shared_services_account_arn = var.shared_services_account_arn
#   prefix = ""
# }
provider "random" {
  version = "~> 2.2.1"
}

resource "random_string" "random" {
  length  = 10
  upper   = false
  special = false
}

module "logging_vpc" {
  source     = "./modules/vpc"
  prefix     = module.label.id
  region     = data.aws_region.current_region.id
  cidr_block = "10.193.0.0/16" //warning changing this in a applied workspace will cause an error! https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/467

  providers = {
    aws = aws.env
  }
}

module "ost_vpc_peering" {
  source  = "./modules/vpc_peering"
  enabled = var.enable_peering

  source_route_table_ids = module.logging_vpc.private_route_table_ids
  source_vpc_id          = module.logging_vpc.vpc_id

  target_aws_account_id = var.ost_aws_account_id
  target_vpc_cidr_block = var.ost_vpc_cidr_block
  target_vpc_id         = var.ost_vpc_id

  tags = module.label.tags

  providers = {
    aws = aws.env
  }
}

module "customLoggingApi" {
  source = "./modules/customLoggingApi"
  prefix = module.label.id
  region = data.aws_region.current_region.id

  providers = {
    aws = aws.env
  }
}

module "logging" {
  source     = "./modules/logging"
  vpc_id     = module.logging_vpc.vpc_id
  subnet_ids = module.logging_vpc.private_subnets
  prefix     = module.label.id
  tags       = module.label.tags

  providers = {
    aws = aws.env
  }
}
