locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = var.name
    Example    = var.name
  }
}

data "aws_availability_zones" "available" {}

# https://aws.amazon.com/blogs/aws/new-for-amazon-efs-iam-authorization-and-access-points/
# https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelasticfilesystem.html
module "efs" {
  source = "terraform-aws-modules/efs/aws"

  create = true

  name             = "${var.name}-efs"
  creation_token   = "${var.name}-efs"
  encrypted        = false
  kms_key_arn      = null

  performance_mode = null
  throughput_mode  = null
  provisioned_throughput_in_mibps = null

  #lifecycle_policy = {
  #  transition_to_ia                    = "AFTER_30_DAYS"
  #  transition_to_primary_storage_class = "AFTER_1_ACCESS"
  #}

  # File system policy
  attach_policy                      = false
  bypass_policy_lockout_safety_check = false
  policy_statements                  = []

  mount_targets              = { for k, v in zipmap(local.azs, var.private_subnets) : k => { subnet_id = v } }
  security_group_description = "${var.name} - EFS security group"
  security_group_vpc_id      = var.vpc_id
  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = var.private_subnets_cidr_blocks
    }
  }

  # Access point(s)
  access_points = {
    posix_example = {
      name = "posix-example"
      posix_user = {
        gid            = 1001
        uid            = 1001
        secondary_gids = [1002]
      }

      tags = {
        Additional = "yes"
      }
    }
    root_example = {
      root_directory = {
        path = "/example"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }


  tags = local.tags
}

module "efs_default" {
  source = "terraform-aws-modules/efs/aws"

  name = "${var.name}-efs-default"
}
