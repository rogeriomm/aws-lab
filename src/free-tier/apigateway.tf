# https://github.com/terraform-aws-modules/terraform-aws-apigateway-v2/tree/master/examples/vpc-link-http
# https://docs.aws.amazon.com/apigateway/latest/developerguide/using-service-linked-roles.html
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name = "${var.name}-api-gateway"
  description   = "HTTP API Gateway with VPC links"
  protocol_type = "HTTP"

  create_api_domain_name = false

  vpc_links = {
    my-vpc = {
      name               = "example"
      security_group_ids = [module.security_group_api_gateway.security_group_id]
      subnet_ids         = module.vpc.public_subnets
    }
  }

  tags = {
    Name = "private-api"
  }
}
