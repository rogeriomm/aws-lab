# https://github.com/terraform-aws-modules/terraform-aws-lambda
# https://www.logicloud.tech/articles/terraform/aws-lambda
# store package locally
# iam:CreatePolicy
module "lambda_function_python_1" {
  source = "terraform-aws-modules/lambda/aws"

  create = true

  function_name = "lambda_function_python_1"
  description   = "Lambda function, Python, 1"
  handler       = "lambda_function_1.lambda_handler"
  runtime       = "python3.8"

  publish = true
  tracing_mode = "Active"

  source_path   = "lambda/samples/python/blank-python/."

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
    }
  }

  ######################
  # Additional policies
  ######################
  attach_policy_json = true
  policy_json        = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "xray:GetSamplingStatisticSummaries"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF

  # https://github.com/terraform-aws-modules/terraform-aws-eventbridge/blob/d1aa8f6851d84c32118b43c1af85012366e92e04/examples/complete/main.tf#L170
  attach_policies    = true
  policies           = ["arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess", "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess", "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"]
  number_of_policies = 3

  timeout = 2
}

module "lambda_function_go" {
  source = "terraform-aws-modules/lambda/aws"

  create = true

  function_name = "lambda_function_go_1"
  description   = "Lambda function, Go, 1"
  handler       = "main"
  runtime       = "go1.x"

  publish = true
  tracing_mode = "Active"

  source_path     = "lambda/samples/golang/blank-go/function/main"

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
    }
  }

  timeout = 2
}

module "lambda_function_java" {
  source = "terraform-aws-modules/lambda/aws"

  create = true

  function_name = "lambda_function_java_1"
  description   = "Lambda function, Java, 1"
  handler       = "example.Handler::handleRequest"
  runtime       = "java11"

  publish = true
  tracing_mode = "Active"

  source_path     = "lambda/samples/java/blank-java/build/."

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
    }
  }

  timeout = 2
}

#
module "lambda_function_rust" {
  source = "terraform-aws-modules/lambda/aws"

  create = true

  function_name = "lambda_function_rust_1"
  description   = "Lambda function, RUST, 1"
  handler       = "example.Handler::handleRequest"
  runtime       = "provided.al2" # https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html

  publish = true
  tracing_mode = "Active"

  source_path   = "lambda/samples/rust/basic-sqs/target/lambda/basic-sqs/bootstrap" # https://docs.aws.amazon.com/sdk-for-rust/latest/dg/lambda.html

  vpc_subnet_ids         = module.vpc.intra_subnets
  vpc_security_group_ids = [module.security_group_lambda.security_group_id]
  attach_network_policy  = true

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*/*"
    }
  }

  timeout = 2
}

module "security_group_lambda" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.name}-lambda"
  description = "Lambda security group"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.api_gateway_security_group.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]
}
