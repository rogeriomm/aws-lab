provider "aws" {
  profile = var.profile
  region = local.region
}

terraform {
  backend "s3" {}
}

locals {
  region = "us-east-1"

  user_data = <<-EOT
  #!/bin/bash
  echo "Hello Terraform!"
  EOT

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = var.ec2_ssh_key_name
  public_key = file(var.ec2_ssh_public_key_path)
}

module "ec2-free-tier" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.name}-network-interface"

  instance_type = "t2.micro"
  key_name = aws_key_pair.ec2_key_pair.key_name

  subnet_id              = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids = [module.security_group_ec2.security_group_id]

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

# https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/v3.19.0/examples/simple-vpc

// https://github.com/terraform-aws-modules/terraform-aws-iam

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = var.name
  cidr = "10.99.0.0/18"

  azs                 = ["${local.region}a", "${local.region}b", "${local.region}c"]

  public_subnets      = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets     = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  database_subnets    = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]
  intra_subnets       = ["10.99.10.0/24","10.99.11.0/24", "10.99.12.0/24"]
  outpost_subnets     = []
  elasticache_subnets = []
  redshift_subnets    = []

  enable_dns_support = true
  enable_nat_gateway = false # Not on free tier
  single_nat_gateway = false # Not on free tier
  create_igw         = true

  tags = local.tags
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/
    # aws ssm get-parameters-by-path --path "/aws/service/ami-amazon-linux-latest" --region us-east-1
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}


module "security_group_ec2" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name}_ec2"
  description = "EC2 Security group"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  # https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
  ingress_rules       = ["https-443-tcp", "ssh-tcp"]
  egress_rules        = ["all-all"]

  tags = local.tags
}

resource "aws_placement_group" "web" {
  name     = var.name
  strategy = "cluster"
}

resource "aws_network_interface" "this" {
  subnet_id = element(module.vpc.private_subnets, 0)
}
