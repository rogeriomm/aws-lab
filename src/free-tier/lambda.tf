# https://github.com/terraform-aws-modules/terraform-aws-lambda
# https://www.logicloud.tech/articles/terraform/aws-lambda
# store package locally
# iam:CreatePolicy
module "lambda_function_python_1" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda_function_python_1"
  description   = "Lambda function, Python, 1"
  handler       = "lambda_function_1.lambda_handler"
  runtime       = "python3.8"

  source_path     = "lambda/samples/python/."

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  timeout = 2  # The amount of time your Lambda Function has to run in seconds

  tags = {
    Module = "my-lambda1"
  }
}

module "lambda_function_go" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda_function_go_1"
  description   = "Lambda function, Go, 1"
  handler       = "main"
  runtime       = "go1.x"

  source_path     = "lambda/samples/golang/blank-go/function/main"

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  timeout = 4

  tags = {
    Module = "my-lambda1"
  }
}

module "lambda_function_java" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda_function_java_1"
  description   = "Lambda function, Java, 1"
  handler       = "example.Handler::handleRequest"
  runtime       = "java11"

  source_path     = "lambda/samples/java/blank-java/build/."

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  timeout = 4

  tags = {
    Module = "my-lambda1"
  }
}

#
module "lambda_function_rust" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "lambda_function_rust_1"
  description   = "Lambda function, RUST, 1"
  handler       = "example.Handler::handleRequest"
  runtime       = "provided.al2" # https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html

  source_path     = "lambda/samples/rust/basic-sqs/target/lambda/basic-sqs/bootstrap" # https://docs.aws.amazon.com/sdk-for-rust/latest/dg/lambda.html

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  timeout = 4

  tags = {
    Module = "my-lambda1"
  }
}

module "security_group_lambda" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name}_lambda"
  description = "PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Lambda access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}
