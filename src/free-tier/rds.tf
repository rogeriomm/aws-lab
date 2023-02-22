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
