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

module "db" {
  source  = "terraform-aws-modules/rds/aws"

  identifier = "labdb"

  db_name  = "labdb"
  username = "postgres"
  port     = "3306"

  engine            = "postgres"
  engine_version    = var.engine_version

  multi_az          = false             # Free tier, single AZ
  instance_class    = "db.t3.micro"     # Free tier: ["db.t2.micro", "db.t3.micro", "db.t4.micro"]
  allocated_storage     = 20            # Free tier: <= 20
  max_allocated_storage = 20            # Free tier: <= 20

  # DB parameter group
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group
  # https://github.com/kiwicom/terraform-aws-rds-core/blob/master/main.tf
  family = "postgres${var.major_version[var.engine_version]}"

  # DB option group
  major_engine_version = var.major_version[var.engine_version]

  # FIXME
  iam_database_authentication_enabled = true

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group_db.security_group_id]
  create_db_subnet_group = false
  subnet_ids             = module.vpc.database_subnets

  maintenance_window  = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  create_cloudwatch_log_group     = false

  # Database Deletion Protection
  deletion_protection = false
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.name}-bucket-1"
  acl    = "private"

  versioning = {
    enabled = false
  }
}

# https://github.com/terraform-aws-modules/terraform-aws-lambda
# https://www.logicloud.tech/articles/terraform/aws-lambda
# store package locally
# iam:CreatePolicy
module "lambda_function_python_1" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda_function_python_1"
  description   = "Lambda function, Python, 1"
  handler       = "index.lambda_handler"
  runtime       = "python3.8"

  source_path     = "lambda/samples/python/lambda_function_1.py"

  timeout = 2  # The amount of time your Lambda Function has to run in seconds

  tags = {
    Module = "my-lambda1"
  }
}

# https://github.com/awsdocs/aws-lambda-developer-guide/tree/main/sample-apps/blank-go
module "lambda_function_go" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda_function_go_1"
  description   = "Lambda function, Go, 1"
  handler       = "main"
  # https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html
  runtime       = "go1.x"

  source_path     = "lambda/samples/golang/blank-go/function/main"

  timeout = 2  # The amount of time your Lambda Function has to run in seconds

  tags = {
    Module = "my-lambda1"
  }
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

  azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets   = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets  = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
  database_subnets = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]
  #redshift_subnets = ["10.99.10.0/24", "10.99.11.0/24", "10.99.12.0/24"]

  #enable_nat_gateway = false
  #single_nat_gateway = true
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

module "security_group_db" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name}_db"
  description = "PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
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
